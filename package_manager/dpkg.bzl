def _dpkg_list_impl(repository_ctx):
  repository_ctx.file("file/BUILD", """
package(default_visibility = ["//visibility:public"])
deb_files = glob(["*.deb"])
exports_files(deb_files + ["packages.bzl"])
""")

  args = [
      repository_ctx.path(repository_ctx.attr._dpkg_parser),
      "--package-files", ",".join([repository_ctx.path(src_path) for src_path in repository_ctx.attr.sources]),
      "--packages", ",".join(repository_ctx.attr.packages),
      "--workspace-name", repository_ctx.name,
  ]

  result = repository_ctx.execute(args)
  if result.return_code:
    fail("dpkg_parser command failed: %s (%s)" % (result.stderr, " ".join(args)))

_dpkg_list = repository_rule(
    _dpkg_list_impl,
    attrs = {
        "sources": attr.label_list(
            allow_files = True,
        ),
        "packages": attr.string_list(),
        "_dpkg_parser": attr.label(
            executable = True,
            default = Label("@dpkg_parser//file:dpkg_parser.par"),
            cfg = "host",
        ),
    },
)

def _dpkg_src_impl(repository_ctx):
  repository_ctx.file("file/BUILD", """
package(default_visibility = ["//visibility:public"])
exports_files(["Packages.json", "os_release.tar"])
""")
  args = [
      repository_ctx.path(repository_ctx.attr._dpkg_parser),
      "--download-and-extract-only=True",
      "--mirror-url=" + repository_ctx.attr.url,
      "--arch=" + repository_ctx.attr.arch, 
      "--distro=" + repository_ctx.attr.distro,
      "--snapshot=" + repository_ctx.attr.snapshot,
      "--sha256=" + repository_ctx.attr.sha256,
  ]

  result = repository_ctx.execute(args)
  if result.return_code:
    fail("dpkg_parser command failed: %s (%s)" % (result.stderr, " ".join(args)))

_dpkg_src = repository_rule(
    _dpkg_src_impl,
    attrs = {
        "url": attr.string(),
        "arch": attr.string(),
        "distro": attr.string(),
        "snapshot": attr.string(),
        "sha256": attr.string(),
        "_dpkg_parser": attr.label(
            executable = True,
            default = Label("@dpkg_parser//file:dpkg_parser.par"),
            cfg = "host",
        ),
    },
)

def dpkg_list(**kwargs):
  _dpkg_list(**kwargs)

def dpkg_src(**kwargs):
  _dpkg_src(**kwargs)
