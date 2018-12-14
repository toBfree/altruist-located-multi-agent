/***
* Name: Altruism
* Author: Foug
* Description: no
* Tags: Tag1, Tag2, TagN
***/

model Altruism

/* Insert your model definition here */

global {
	file shape_file_walls <- file("../includes/shape.shp");
	geometry shape <- envelope(shape_file_walls);
	init{
		create walls from:shape_file_walls;
		create spawn_point{
			p <- {0.3,0.35000};
			location <- p;
		}
		/*create sources number:5 {
			p <- {rnd(100,475), rnd(100,475)};
			location <- p;
		}*/
		create sources {
			location <- {0.25, 1.05};
		}
		create sources {
			location <- {0.6, 1.25};
		}
		create sources {
			location <- {1.45, 0.3};
		}
		create sources {
			location <- {1.65, 1.0};
		}
		create sources {
			location <- {1.3, 1.3};
		}
		list<spawn_point> sp <- list<spawn_point>(spawn_point);
		list<sources> sour <- list<sources>(sources);
		create alt_agent number:50 {
			location <-  any_location_in (one_of (sp));
			the_target <- any_location_in (one_of (sour));
			spawning_point <-  any_location_in (one_of (sp));
			carry <- false;
		}
		
		
		
	}
}

species spawn_point {
	point p;
	
	aspect square{
		draw square(0.25) color:rgb("gray");
	}
}

species sources {
	point p;
	
	aspect square{
		draw square(0.15) color:rgb("red");
	}
}

species walls {
	aspect base{
		draw shape color:rgb("blue");
	}
}

species alt_agent skills:[moving]{
	float speed <- 0.05 + rnd(0.005);
	point the_target;
	point spawning_point;
	bool carry;
	agent target;
	
	reflex move when: the_target != nil {
		if(carry = false){
			path p <- self goto[target::the_target, return_path:: true];
		}
		else{
			path p <- self goto[target::spawning_point, return_path:: true];
		}
		
		if(location = the_target){
			carry <- true;
		}
		else if(location = spawning_point){
			carry <- false;
		}
	}
	
	
	
	aspect circle{
		draw circle(0.04) color:rgb("green");
	}
}

experiment main_experiment type:gui{
	parameter "Shapefile for the walls:" var: shape_file_walls category: "GIS" ;
	output{
		display map{
			species spawn_point aspect:square;
			species sources aspect:square;
			species alt_agent aspect:circle;
			species walls aspect:base;	
		}
	}	
}