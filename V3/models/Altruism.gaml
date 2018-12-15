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
	float max_power <- 10.0;
	float max_ressources <- 100.0;
	init{
		create walls from:shape_file_walls;
		create spawn_point{
			location <- {0.3,0.35};
			current_riches <-0.0;
		}
		/*create sources number:5 {
			p <- {rnd(100,475), rnd(100,475)};
			location <- p;
		}*/
		create sources {
			location <- {0.25, 1.05};
			current_ressources <- max_ressources;
		}
		create sources {
			location <- {0.6, 1.25};
			current_ressources <- max_ressources;
		}
		create sources {
			location <- {1.45, 0.3};
			current_ressources <- max_ressources;
		}
		create sources {
			location <- {1.65, 1.0};
			current_ressources <- max_ressources;
		}
		create sources {
			location <- {1.3, 1.3};
			current_ressources <- max_ressources;
		}
		list<spawn_point> sp <- list<spawn_point>(spawn_point);
		list<sources> sour <- list<sources>(sources);
		create alt_agent number:50 {
			location <-  any_location_in (one_of (sp));
			my_source <- one_of(sour);
			my_spawn <- one_of (sp);
			//the_target <- any_location_in (one_of (sour));
			//spawning_point <-  any_location_in (one_of (sp));
			carry <- false;
			current_power <- max_power;
		}
		
		
		
	}
}

species spawn_point {
	float current_riches;
	
	action add_ressources{
		current_riches <- current_riches + 1;
	}
		
	aspect square{
		draw square(0.25) color:rgb("gray");
		draw string(current_riches with_precision 2) size: 10 color: #black ;
	}
}

species sources {
	float current_ressources;
	
	action get_ressources{
		current_ressources <- current_ressources - 1;
	}
	
	aspect square{
		draw square(0.15) color:rgb("red");
		draw string(current_ressources with_precision 2) size: 5 color: #black ;
	}
}

species walls {
	aspect base{
		draw shape color:rgb("blue");
	}
}

species alt_agent skills:[moving]{
	float speed <- 0.03 + rnd(0.001);
	
	bool carry;
	float current_power;
	agent my_source;
	agent my_spawn;

	//geometry circle <- 0.01 around circle(0.1);
	
	/*reflex move when: the_target != nil {
		if(carry = false){
			path p <- self goto[target::the_target, return_path:: true];
		}
		else{
			path p <- self goto[target::spawning_point, return_path:: true];
		}
		
		if(location = the_target){
			carry <- true;
			ask source{
				get_ressources;
			}
		}
		else if(location = spawning_point){
			carry <- false;
			current_power <- max_power;
			ask spawn{
				get_ressources;
			}
		}
		else{
			current_power <- current_power - 0.1;
		}
	}*/
	
	reflex move when: my_source != nil {
		if(carry = false){
			path p <- self goto[target::my_source, return_path:: true];
		}
		else{
			path p <- self goto[target::my_spawn, return_path:: true];
		}
		
		/*if((location.x < my_source.x) and (location.y < (my_source.y +0.1) )){
			carry <- true;
			ask my_source{
				do get_ressources;
			}
		}*/
		
		if(location = my_source.location){
			carry <- true;
			ask sources at_distance 0.05{
				do get_ressources;
			}
		}
		else if(location = my_spawn.location){
			carry <- false;
			current_power <- max_power;
			ask spawn_point{
				do add_ressources;
			}
		}
		else{
			current_power <- current_power - 0.1;
		}
	}
	
	reflex out_of_energy when:current_power = 0{
		do die;
	}
	
	
	
	
	aspect circle{
		draw circle(0.04) color:rgb("green");
		/*geometry cone <- cone(0,45);
		draw cone(0.1,1.0);*/
		//draw 0.01 around circle(0.1);
		draw string(current_power with_precision 2) size: 3 color: #black ;
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