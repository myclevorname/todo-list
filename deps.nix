# generated by zon2nix (https://github.com/nix-community/zon2nix)

{ linkFarm, fetchzip, fetchgit }:

linkFarm "zig-packages" [
  {
    name = "N-V-__8AAAHFTwBfBg00dnFXcYkNbjC8BSyi1CDcrnh12ypL";
    path = fetchzip {
      url = "https://github.com/raysan5/raygui/archive/33f1659.tar.gz";
      hash = "sha256-0O706tiG02jLBZEoy+/itlZDaBEe+CoFqt8a3eFxvyc=";
    };
  }
  {
    name = "N-V-__8AABHMqAWYuRdIlflwi8gksPnlUMQBiSxAqQAAZFms";
    path = fetchgit {
      url = "https://github.com/hexops/xcode-frameworks";
      rev = "9a45f3ac977fd25dff77e58c6de1870b6808c4a7";
      hash = "sha256-xveFYoQu0BT+ZtEsyca/zdQ/so9jPK56SeX3xmF3iro=";
    };
  }
  {
    name = "N-V-__8AALRTBQDo_pUJ8IQ-XiIyYwDKQVwnr7-7o5kvPDGE";
    path = fetchgit {
      url = "https://github.com/emscripten-core/emsdk";
      rev = "3.1.50";
      hash = "sha256-YUwb8yfz26Tfz4wyN13MBsdyA40ygJwfxHWt4eFMvQE=";
    };
  }
  {
    name = "SDL-2.32.2-JToi31GUEgEEqcSkGTse-l1nCSkB30CRkWPAQ2moXSFp";
    path = fetchgit {
      url = "https://github.com/david-vanderson/SDL";
      rev = "7c01b8a263915dc1aa0067d7ff9089dbe047cef9";
      hash = "sha256-zh+XoDDgou4XoxK/DTqxj4SocRwi2ZrQzvWAMOwD2Mg=";
    };
  }
  {
    name = "dvui-0.2.0-AQFJmavOzQCqVurzQUMj3YLrBcI0IImQNCBKHIsfI3gk";
    path = fetchgit {
      url = "https://github.com/david-vanderson/dvui";
      rev = "13a86d035894087fd8414b0e3b045f487b8ca84d";
      hash = "sha256-zatZxGGqs5R8SDJX/2QM75wgivshEbpnWa3wQrLOBb8=";
    };
  }
  {
    name = "freetype-2.13.0-AAAAAI6NqAA4EbABl7qfk5qBFJQb2xjUIcP6SY7EBFvJ";
    path = fetchgit {
      url = "https://github.com/rohlem/freetype-update-zig";
      rev = "a50182dc5787a8d49dd1ad922699a1c8771aa34a";
      hash = "sha256-xZd/ouMqnLahBYv2CMkTDx3z5BCdbrwOPHmR/Gla0y0=";
    };
  }
  {
    name = "known_folders-0.0.0-Fy-PJtLDAADGDOwYwMkVydMSTp_aN-nfjCZw6qPQ2ECL";
    path = fetchgit {
      url = "https://github.com/ziglibs/known-folders";
      rev = "aa24df42183ad415d10bc0a33e6238c437fc0f59";
      hash = "sha256-YiJ2lfG1xsGFMO6flk/BMhCqJ3kB3MnOX5fnfDEcmMY=";
    };
  }
  {
    name = "raylib-5.5.0-whq8uFq2NATO2aMsuIJtFw9YBQyYfVbO-ln5TAvN0bWP";
    path = fetchgit {
      url = "https://github.com/raysan5/raylib";
      rev = "688a81d3334c789493b24617778a334ac786f52e";
      hash = "sha256-vJt6SlIQVetd7SYoUjduuBusPC5FuCdjJeX9a0BC/0M=";
    };
  }
  {
    name = "sdl-0.2.1+3.2.10-7uIn9PLkfQHKJO7TvSXbVa0VnySCHbLz28PDZIlKWF4Y";
    path = fetchgit {
      url = "https://github.com/castholm/SDL";
      rev = "f6bbe8ac5e7b901db69ba62f017596090c362d84";
      hash = "sha256-EwjRWsEbX9QQZGDUyyy4svTF+b6RcJG1k1W4eUpuZ4E=";
    };
  }
  {
    name = "sdl_linux_deps-0.0.0-Vy5_h4AlfwBtG7MIPe7ZNUANhmYLek_SA140uYk9SrED";
    path = fetchgit {
      url = "https://github.com/castholm/SDL_linux_deps.git";
      rev = "085212f286621835f2638cb0cfff078fe515341a";
      hash = "sha256-2NWnMwJNl7JzSRq6cym1CJjlEDIlDwvWCfbD+Q1Ig4w=";
    };
  }
  {
    name = "zigwin32-25.0.28-preview-AAAAAHsJ-wPA4nREAzT_OOkF6gLrornNuHqREfHDADoS";
    path = fetchgit {
      url = "https://github.com/marlersoft/zigwin32";
      rev = "be58d3816810c1e4c20781cc7223a60906467d3c";
      hash = "sha256-wG4C9jAsIxU4D99hgzbWrQjaaS4XVbN6TMFa3mbvrEo=";
    };
  }
]
