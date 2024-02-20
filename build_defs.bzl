# Copyright (c) 2019 The Pybind Development Team. All rights reserved.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Build rules for pybind11."""

def register_extension_info(**kwargs):
    pass

PYBIND_COPTS = select({
    Label("@pybind11//:msvc_compiler"): [],
    "//conditions:default": ["-fexceptions"],
})

PYBIND_FEATURES = [
    "-use_header_modules",  # Required for pybind11.
    "-parse_headers",
]

PYBIND_DEPS = [
    Label("@pybind11//:pybind11"),
    "@rules_python//python/cc:current_py_cc_headers",
]

# Builds a Python extension module using pybind11.
# This can be directly used in python with the import statement.
# This adds rules for a .so binary file.
def pybind_extension(
        name,
        copts = [],
        features = [],
        linkopts = [],
        tags = [],
        deps = [],
        **kwargs):
    # Mark common dependencies as required for build_cleaner.
    tags = tags + ["req_dep=%s" % dep for dep in PYBIND_DEPS]

    native.cc_binary(
        name = name + ".so",
        copts = copts + PYBIND_COPTS + select({
            Label("@pybind11//:msvc_compiler"): [],
            "//conditions:default": ["-fvisibility=hidden"],
        }),
        features = features + PYBIND_FEATURES,
        linkopts = linkopts + select({
            "@platforms//os:osx": ["-undefined", "dynamic_lookup"],
            Label("@pybind11//:msvc_compiler"): [],
            "//conditions:default": ["-Wl,-Bsymbolic"],
        }),
        linkshared = 1,
        tags = tags,
        deps = deps + PYBIND_DEPS,
        **kwargs
    )

# Builds a pybind11 compatible library. This can be linked to a pybind_extension.
def pybind_library(
        name,
        copts = [],
        features = [],
        tags = [],
        deps = [],
        **kwargs):
    # Mark common dependencies as required for build_cleaner.
    tags = tags + ["req_dep=%s" % dep for dep in PYBIND_DEPS]

    native.cc_library(
        name = name,
        copts = copts + PYBIND_COPTS,
        features = features + PYBIND_FEATURES,
        tags = tags,
        deps = deps + PYBIND_DEPS,
        **kwargs
    )

# Builds a C++ test for a pybind_library.
def pybind_library_test(
        name,
        copts = [],
        features = [],
        tags = [],
        deps = [],
        **kwargs):
    # Mark common dependencies as required for build_cleaner.
    tags = tags + ["req_dep=%s" % dep for dep in PYBIND_DEPS]

    native.cc_test(
        name = name,
        copts = copts + PYBIND_COPTS,
        features = features + PYBIND_FEATURES,
        tags = tags,
        deps = deps + PYBIND_DEPS + [
            "@rules_python//python/cc:current_py_cc_libs",
        ],
        **kwargs
    )

# Register extension with build_cleaner.
register_extension_info(
    extension = pybind_extension,
    label_regex_for_dep = "{extension_name}",
)

register_extension_info(
    extension = pybind_library,
    label_regex_for_dep = "{extension_name}",
)

register_extension_info(
    extension = pybind_library_test,
    label_regex_for_dep = "{extension_name}",
)
