/***
* Name: Model3
* Author: root
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Model3

/* Insert your model definition here */
global {
	int intensite <- 100 parameter: "Nombre de voiture" category: "voiture" min: 10 max: 50;
	float duree_autorisee <- 10.0;
	file shape_file_area1 <- file("../includes/Area1.shp");
	file shape_file_base <- file("../includes/base.shp");
	file shape_file_route <- file("../includes/route.shp");
	file shape_file_area2 <- file("../includes/Area2.shp");
	file shape_file_entre <- file("../includes/Entre.shp");
	file shape_file_sortie <- file("../includes/sortie.shp");
	geometry shape <- envelope(shape_file_base);
	graph chemin;
	float point_financier;

	init {
		create espace from: shape_file_base;
		create road from: shape_file_route;
		list<road> route <- road where (each.name != "road2");
		chemin <- as_edge_graph(route);
		create place1 from: shape_file_area1 with: [name:: string(read("NATURE"))] {
			if name = "place10" {
				color <- #gray;
			}

		}

		create place2 from: shape_file_area2 with: [name:: string(read("NATURE"))] {
			if name = "place20" {
				color <- #gray;
			}

		}

		create entre from: shape_file_entre with: [name:: string(read("nature"))] {
			if name = "entre0" {
				point loca <- self.location;
			}

		}

		create sortie from: shape_file_sortie;
		create voiture number: intensite {
			list<point> demarrer;
			point p;
			loop x from: 0 to: 5 { // or loop name:i from :0 to :5 -> the name
				loop y from: 0 to: 5 {
					p <- p + {x, y};
					add p to: demarrer;
				}

			}

			location <- any_location_in(one_of(demarrer));
		}

	}

}

species espace {
	string type;
	rgb color <- #gray;

	aspect base {
		draw shape color: color;
	}

}

species place1 {
	string statut <- "libre";
	rgb color <- #white;
	int size <- 80;

	aspect base {
		draw shape color: color;
	}

}

species place2 {
	string statut <- "libre";
	int size <- 45;
	rgb color <- #white;

	aspect base {
		draw shape color: color;
	}

}

species road {
	rgb color <- #black;

	aspect base {
		draw shape color: color;
	}

}

species entre {
	rgb color <- #green;

	reflex garer {
		list<place1> parking1 <- place1 where (each.name != "place10");
		list<place2> parking <- place2 where (each.name != "place20");
		list<voiture> vehicule <- voiture where (each.attrib_place = 0);
		int placedispo <- length(parking1) + length(parking);
		place2 place;
		place1 placeG;
		int i <- 0;
		int j <- 0;
		int x2 <- 0;
		loop k over: vehicule {
			if (x2 < placedispo) {
				if ((i < length(parking1)) and (k.size > 45)) {
					placeG <- parking1 at i;
					ask k {
						do action: goto target: placeG.location;
					}

					set placeG.statut <- "occupe";
					put placeG in: parking1 at: i;
					i <- i + 1;
				}

				if (i >= length(parking1)) and (k.size < 45) {
					place <- parking at j;
					ask k {
						do action: goto target: place.location;
					}

					set place.statut <- "occupe";
					put place in: parking at: j;
					j <- j + 1;
				}

			}

			if (x2 >= placedispo) {
				ask k {
					list<point> sortiepoint;
					point p;
					loop x from: 90 to: 100 { // or loop name:i from :0 to :5 -> the name
						loop y from: 0 to: 5 {
							p <- p + {x, y};
							add p to: sortiepoint;
						}

					}

					do action: goto target: {100, 5};
				}

			}

			x2 <- i + j;
		}

		/*loop f over: parking {
			parking <- place2 where (each.statut = "libre");
			but <- f;
			set f.statut <- "occupe";
			 target: f.location;
		}*/
	}

	aspect base {
		draw circle(10) color: color;
	}

}

species sortie {
	string type;
	rgb color <- #yellow;

	reflex sortir {
		list<voiture> vehicule <- voiture where (each.test_place = 1);
		float frais_park <- 0.0;
		loop k over: vehicule {
			frais_park <- frais_park + k.prix;
			ask k {
				do action: goto target: {100, 5};
				color <- #red;
				seuil_rester <- seuil_rester - 0.003;
				if (seuil_rester < 0.4) {
					do die;
				}

			}

			point_financier <- frais_park;
			create voiture number: 2 {
				list<point> demarrer;
				point p;
				loop x from: 0 to: 5 { // or loop name:i from :0 to :5 -> the name
					loop y from: 0 to: 5 {
						p <- p + {x, y};
						add p to: demarrer;
					}

				}

				location <- any_location_in(one_of(demarrer));
			}

		}

	}

	aspect base {
		draw shape color: color;
	}

}

species voiture skills: [moving] {
	rgb color <- #blue;
	int size <- 20 + rnd(50);
	float speed <- 30 + rnd(10);
	//float duree <- time;
	int attrib_place <- 0;
	float seuil_rester <- 60 + rnd(20);
	float prix <- 45 * seuil_rester;
	int test_place <- 0;

	reflex entrer {
		list<entre> enterpoint <- entre where (each.location != nil);
		do action: goto target: any_location_in(one_of(enterpoint));
	}

	reflex durer {
		list<entre> enterpoint <- entre where (each.location != nil);
		if (self.location != any_location_in(one_of(enterpoint))) {
			if (self.location != {100, 5}) {
				seuil_rester <- seuil_rester - 0.002;
			}

		}

	}

	reflex sortir when: (seuil_rester < 1) {
		list<sortie> sortiepoint <- sortie where (each.name = "sortie0");
		do action: goto target: any_location_in(one_of(sortiepoint));
		test_place <- 1;
		if (size > 45) {
			prix <- 80 * seuil_rester;
		}

	}

	aspect base {
		draw square(size) color: color;
	}

}

experiment model3 type: gui {
	output {
		display parking_display type: java2D {
			species espace aspect: base;
			species place1 aspect: base;
			species place2 aspect: base;
			species entre aspect: base;
			species sortie aspect: base;
			species voiture aspect: base;
		}

		display Montant refresh: every(5 #s) {
			chart "Montant" type: xy {
				data "montant par_heure" value: point_financier;
			}

		}

		display parking_management refresh: every(1 #s) {
			chart "parking_data" type: histogram {
				data "under_7m" value: length(list(place1) where (each.statut = "libre")) + length(list(place2) where (each.statut = "libre"));
			}

		}

	}

}
