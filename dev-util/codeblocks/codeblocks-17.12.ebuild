# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

WX_GTK_VER="3.0"

inherit autotools eutils flag-o-matic wxwidgets xdg-utils

DESCRIPTION="The open source, cross platform, free C++ IDE"
HOMEPAGE="http://www.codeblocks.org/"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~x86 ~x86-fbsd"
SRC_URI="mirror://sourceforge/codeblocks/${P/-/_}.tar.xz"

# USE="fortran" enable FortranProject plugin (v1.5)
# that is delivered with Code::Blocks 17.12 source code.
# https://sourceforge.net/projects/fortranproject
# http://cbfortran.sourceforge.net

IUSE="contrib debug fortran pch static-libs"

S="${WORKDIR}/${P}"

RDEPEND="app-arch/zip
	x11-libs/wxGTK:${WX_GTK_VER}[X]
	contrib? (
		app-text/hunspell
		dev-libs/boost:=
		dev-libs/libgamin
	)"

DEPEND="${RDEPEND}
	fortran? (
		sys-devel/autoconf:2.69
		sys-devel/automake
	)
	virtual/pkgconfig"

src_prepare() {
	if ! use fortran ; then
		default
	else
		epatch "${FILESDIR}/FortranProject_autotools_build.diff"
		eapply_user
		# Rerun autotools
		einfo "Regenerating autotools files..."
		WANT_AUTOCONF=2.69 eautoconf
		# codeblocks tarball makefile.in files were generated with automake 1.13
		# but after patching for FortranProject plugin the rebuild of tree is successful
		# also with automake:1.15 so dependence of =automake:1.13 isn't obligatory
		# there will be only warning:
		WANT_AUTOMAKE=1.13 eautomake
	fi
}

src_configure() {
	touch "${S}"/revision.m4 -r "${S}"/m4/acinclude.m4
	setup-wxwidgets

	append-cxxflags $(test-flags-CXX -fno-delete-null-pointer-checks)

	# set --with-contrib-plugins or --without-contrib-plugins
	use fortran || CONF_WITH_LST=$(use_with contrib contrib-plugins all)
	use fortran && CONF_WITH_LST=$(use_with contrib contrib-plugins all)
	use contrib || CONF_WITH_LST=$(use_with fortran contrib-plugins FortranProject)

	econf \
		--with-wx-config="${WX_CONFIG}" \
		$(use_enable debug) \
		$(use_enable pch) \
		$(use_enable static-libs static) \
		${CONF_WITH_LST}
}

pkg_postinst() {
	if [[ ${WX_GTK_VER} == "3.0" || ${WX_GTK_VER} == "3.0-gtk3" ]]; then
		elog "KNOWN ISSUE:"
		elog "The symbols browser is disabled in wx3.x builds due to it causes crashes."
		elog "For more information see ticket https://sourceforge.net/p/codeblocks/tickets/225/"
		elog "with related commits https://sourceforge.net/p/codeblocks/code/11027/"
		elog "and https://sourceforge.net/p/codeblocks/code/11141/"
	fi

	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}
