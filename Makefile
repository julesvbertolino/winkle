.PHONY: build run app open dmg icon clean

# Build de développement
build:
	swift build

# Lance le binaire nu (pas de notifications ni login item — utiliser `make open`)
run:
	swift run

# Construit build/Winkle.app (release, signé ad-hoc)
app:
	./scripts/bundle.sh

# Construit puis lance l'app bundlée
open: app
	open build/Winkle.app

# Construit le .dmg partageable (build/Winkle-x.y.z.dmg)
dmg:
	./scripts/make-dmg.sh

# (Re)génère l'icône .icns
icon:
	./scripts/make-icns.sh

clean:
	rm -rf .build build
