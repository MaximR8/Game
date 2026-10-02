# LES DÉCORS DE LA MACHINE — écrit par design/machines/analyser.py --jeu (ne pas modifier à la main).
# Pour chaque décor : ses images (res://machines/<décor>/), la caméra qui pose le plateau dans le creux peint
# (deux champs ; « etirement » : la profondeur étirée à l'image), les alvéoles des lunes [x, y, rayon], l'emblème,
# les flammes [x, y du bas, largeur, hauteur], les éclats — en pixels de l'image (1024 × 1536).
extends RefCounted

const DECORS := {
	"BaseCeleste": {
		"image": "res://machines/BaseCeleste/decor.jpg",
		"or": "res://machines/BaseCeleste/or.png",
		"bloc_dessus": "res://machines/BaseCeleste/bloc-dessus.jpg",
		"bloc_face": "res://machines/BaseCeleste/bloc-face.jpg",
		"cameras": {
			"80": {
				"fov_deg": 80,
				"position": [
					5.4,
					10.2026,
					15.9933
				],
				"plongee_deg": 49.3901,
				"etirement": 1.2749,
				"erreur_px": 0.0
			},
			"90": {
				"fov_deg": 90,
				"position": [
					5.4,
					9.154,
					14.269
				],
				"plongee_deg": 54.267,
				"etirement": 1.1923,
				"erreur_px": 0.0
			}
		},
		"alveoles": [
			[
				264.2,
				208.2,
				25.1
			],
			[
				342.9,
				170.1,
				25.5
			],
			[
				426.8,
				146.2,
				25.5
			],
			[
				511.6,
				137.9,
				25.5
			],
			[
				596.4,
				146.1,
				25.5
			],
			[
				680.0,
				170.0,
				25.5
			],
			[
				759.0,
				208.2,
				25.2
			]
		],
		"embleme": [
			512,
			383
		],
		"r_embleme": 195,
		"flammes": [
			[
				75,
				512,
				26,
				46
			],
			[
				945,
				512,
				26,
				46
			]
		],
		"etoiles": [
			[
				773,
				155
			],
			[
				505,
				278
			],
			[
				506,
				381
			],
			[
				660,
				104
			],
			[
				512,
				206
			],
			[
				414,
				378
			],
			[
				76,
				114
			],
			[
				961,
				31
			],
			[
				872,
				240
			],
			[
				125,
				130
			],
			[
				90,
				309
			],
			[
				569,
				318
			],
			[
				441,
				99
			],
			[
				210,
				32
			],
			[
				934,
				316
			],
			[
				64,
				30
			],
			[
				696,
				266
			],
			[
				80,
				542
			],
			[
				917,
				146
			],
			[
				836,
				202
			],
			[
				943,
				542
			],
			[
				912,
				458
			],
			[
				828,
				27
			],
			[
				578,
				203
			],
			[
				787,
				428
			],
			[
				584,
				99
			],
			[
				320,
				273
			],
			[
				228,
				168
			],
			[
				995,
				89
			],
			[
				592,
				24
			],
			[
				516,
				164
			],
			[
				448,
				46
			],
			[
				869,
				466
			],
			[
				733,
				25
			]
		]
	}
}
