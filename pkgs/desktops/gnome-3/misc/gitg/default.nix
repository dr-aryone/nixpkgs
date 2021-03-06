{ stdenv
, fetchurl
, fetchpatch
, vala_0_42
, intltool
, pkgconfig
, gtk3
, glib
, json-glib
, wrapGAppsHook
, libpeas
, bash
, gobject-introspection
, libsoup
, gtksourceview
, gsettings-desktop-schemas
, adwaita-icon-theme
, gnome3
, gtkspell3
, shared-mime-info
, libgee
, libgit2-glib
, libsecret
, meson
, ninja
, python3
}:

stdenv.mkDerivation rec {
  pname = "gitg";
  version = "3.30.1";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${stdenv.lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "1fz8q1aiql6k740savdjh0vzbyhcflgf94cfdhvzcrrvm929n2ss";
  };

  patches = [
    # Fix build with latest libgit2-glib
    (fetchpatch {
      url = https://gitlab.gnome.org/GNOME/gitg/commit/42bceea265f53fe7fd4a41037b936deed975fc6c.patch;
      sha256 = "1xq245rsi1bi66lswk33pdiazfaagxf77836ds5q73900rx4r7fw";
    })
  ];

  postPatch = ''
    chmod +x meson_post_install.py
    patchShebangs meson_post_install.py
    sed -i '/gtk-update-icon-cache/s/^/#/' meson_post_install.py

    substituteInPlace tests/libgitg/test-commit.vala --replace "/bin/bash" "${bash}/bin/bash"
  '';

  doCheck = false; # FAIL: tests-gitg gtk_style_context_add_provider_for_screen: assertion 'GDK_IS_SCREEN (screen)' failed

  enableParallelBuilding = true;

  buildInputs = [
    adwaita-icon-theme
    glib
    gsettings-desktop-schemas
    gtk3
    gtksourceview
    gtkspell3
    json-glib
    libgee
    libgit2-glib
    libpeas
    libsecret
    libsoup
  ];

  nativeBuildInputs = [
    gobject-introspection
    intltool
    meson
    ninja
    pkgconfig
    python3
    vala_0_42 # fails build with 0.44, drop in >3.30.1
    wrapGAppsHook
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      # Thumbnailers
      --prefix XDG_DATA_DIRS : "${shared-mime-info}/share"
    )
  '';

  passthru = {
    updateScript = gnome3.updateScript {
      packageName = pname;
    };
  };

  meta = with stdenv.lib; {
    homepage = https://wiki.gnome.org/Apps/Gitg;
    description = "GNOME GUI client to view git repositories";
    maintainers = with maintainers; [ domenkozar ];
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
