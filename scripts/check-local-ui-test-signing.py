#!/usr/bin/env python3
"""The local UI test build must not pass signing settings that Xcode applies to every target."""

import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
script = (root / "scripts/build-sapphire-floating-capsule-test.sh").read_text()
project = (root / "Sapphire.xcodeproj/project.pbxproj").read_text()
failures = []

start = script.find("xcodebuild")
end = script.find("\nif [[ -n \"$ORIG_STAMP\" ]]", start)
if start < 0 or end < 0:
    failures.append("could not find the xcodebuild invocation")
    invocation = ""
else:
    invocation = script[start:end]

forbidden = [
    "CODE_SIGN_ENTITLEMENTS=",
    "CODE_SIGN_IDENTITY=",
    "CODE_SIGN_STYLE=",
    "DEVELOPMENT_TEAM=",
    "CODE_SIGNING_ALLOWED=",
    "CODE_SIGNING_REQUIRED=",
    "AD_HOC_CODE_SIGNING_ALLOWED=",
    "REGISTER_APP_GROUPS=",
    "PRODUCT_BUNDLE_IDENTIFIER=",
    "PRODUCT_NAME=",
    "ENABLE_PREVIEWS=",
    "ARCHS=",
    "ONLY_ACTIVE_ARCH=",
]
for line in invocation.splitlines():
    token = line.strip().strip("\\").strip().strip('"')
    for name in forbidden:
        if token.startswith(name):
            failures.append(f"global build setting {name[:-1]} is passed to xcodebuild")

required = [
    "SAPPHIRE_LOCAL_CODE_SIGN_STYLE=Manual",
    "SAPPHIRE_LOCAL_CODE_SIGN_IDENTITY=-",
    "SAPPHIRE_LOCAL_DEVELOPMENT_TEAM=",
    "SAPPHIRE_LOCAL_REGISTER_APP_GROUPS=NO",
    "SAPPHIRE_APP_ENTITLEMENTS=Sapphire/SapphireLocalUITest.entitlements",
    "SAPPHIRE_WIDGET_ENTITLEMENTS=Sapphire/SapphireLocalUITest.entitlements",
    "SAPPHIRE_LOCAL_ENABLE_PREVIEWS=NO",
    "SAPPHIRE_APP_BUNDLE_IDENTIFIER=com.local.sapphire.floatingcapsule.test",
    "SAPPHIRE_APP_PRODUCT_NAME=SapphireFloatingCapsuleTest",
    "SAPPHIRE_SKIP_CRASHLYTICS_UPLOAD=YES",
]
for name in required:
    if name not in invocation:
        failures.append(f"missing scoped setting {name}")

if re.search(r'(?m)^\t\t\t\tCODE_SIGN_IDENTITY = "Apple Development";', project):
    failures.append("a target still hardcodes the Apple Development identity")
if re.search(r"(?m)^\t\t\t\tCODE_SIGN_STYLE = Automatic;", project):
    failures.append("a target still hardcodes automatic signing")
if re.search(r"(?m)^\t\t\t\tDEVELOPMENT_TEAM = KVQFWJ7C7S;", project):
    failures.append("a target still hardcodes the production team")
if "CODE_SIGN_ENTITLEMENTS = Sapphire/SapphireLocalUITest.entitlements;" in project:
    failures.append("the empty test entitlements file is hardcoded instead of selected by a variable")
if 'CODE_SIGN_ENTITLEMENTS = "$(SAPPHIRE_APP_ENTITLEMENTS)";' not in project:
    failures.append("the app target does not use SAPPHIRE_APP_ENTITLEMENTS")
if 'CODE_SIGN_ENTITLEMENTS = "$(SAPPHIRE_WIDGET_ENTITLEMENTS)";' not in project:
    failures.append("the widget target does not use SAPPHIRE_WIDGET_ENTITLEMENTS")
if "SAPPHIRE_WIDGET_ENTITLEMENTS = SapphireAndroidWidgets/SapphireAndroidWidgets.entitlements;" not in project:
    failures.append("the widget lost its production entitlements default")
if "SAPPHIRE_APP_ENTITLEMENTS = Sapphire/SapphireDebug.entitlements;" not in project:
    failures.append("the debug app lost its production entitlements default")
if "SAPPHIRE_LOCAL_DEVELOPMENT_TEAM = KVQFWJ7C7S;" not in project:
    failures.append("the production team default is missing")
if not (root / "PublicExtensionStubs/FileProvider/FileProvider.entitlements").is_file():
    failures.append("the public File Provider entitlements stub is missing")
if "SAPPHIRE_FILEPROVIDER_INFOPLIST_FILE = PublicExtensionStubs/FileProvider/Info.plist;" not in project:
    failures.append("File Provider Info.plist does not default to the tracked public stub")
if "INFOPLIST_FILE = SapphireFileProvider/Info.plist;" in project:
    failures.append("File Provider still requires the untracked private Info.plist")
provider_sources = project.split("F2DE00000000000000000EBB /* Sources */", 1)[1].split("/* End PBXSourcesBuildPhase section */", 1)[0]
if "FileProviderItem.swift" in provider_sources or "HostConnection.swift" in provider_sources:
    failures.append("File Provider still compiles private sources that are not in this tree")
if "PublicExtensionStubs/FileProvider/FileProviderExtension.swift" not in project:
    failures.append("File Provider does not compile the tracked public stub")
if "SAPPHIRE_LOCAL_ENABLE_PREVIEWS = YES;" not in project:
    failures.append("shipping builds lost the SwiftUI preview default")
if 'ENABLE_PREVIEWS = "$(SAPPHIRE_LOCAL_ENABLE_PREVIEWS)";' not in project:
    failures.append("previews are not selected by the local test variable")

bundle_ids = re.findall(r"PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);", project)
if bundle_ids.count('"$(SAPPHIRE_APP_BUNDLE_IDENTIFIER)"') != 2:
    failures.append("only the app target's two configurations may use SAPPHIRE_APP_BUNDLE_IDENTIFIER")
if any("floatingcapsule" in value for value in bundle_ids):
    failures.append("the test bundle id is hardcoded in the project")

if failures:
    print("\n".join(failures), file=sys.stderr)
    sys.exit(1)
print("local UI test signing settings stay scoped to Sapphire targets")
