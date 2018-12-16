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
	spawn_point spawn;
	
	string source_at_location <- "source_at_location";
	string empty_source_location <- "empty_source_location";
	
	predicate source_location <- new_predicate(source_at_location) ;
	predicate choose_source <- new_predicate("choose a source");
	predicate has_ressources <- new_predicate("extract ressources");
	predicate find_ressources <- new_predicate("find resources");
	predicate return_ressources <- new_predicate("return ressources");
	predicate need_power <- new_predicate("get some power back");
	
	
	init{
		create walls from:shape_file_walls;
		create spawn_point{
			spawn <- self;
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
			//my_source <- one_of(sour);
			//my_spawn <- one_of (sp);
			//the_target <- any_location_in (one_of (sour));
			//spawning_point <-  any_location_in (one_of (sp));
			//carry <- false;
			carriage <- 0.0;
			current_power <- max_power;
		}
	}
	reflex end_simulation when: sum(sources collect each.current_ressources) <= 0{
		do pause;
	}
}

species spawn_point {
	float current_riches;
	
	action add_ressources{
		current_riches <- current_riches + 1;
	}
		
	aspect square{
		draw square(0.25) color:rgb("blue");
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
	
	/*reflex out_of_ressources when:current_ressources <= 0.0{
		do die;
	}*/
}

species walls {
	aspect base{
		draw shape color:rgb("gray");
	}
}

species alt_agent skills:[moving] control:simple_bdi{
	float viewdist<-0.2;
	float speed <- 0.07;
	float current_power;
	point target;
	float carriage;
	
	init
	{
		do add_desire(find_ressources);
	}
		
	perceive target:sources where (each.current_ressources > 0) in:viewdist {
		focus id:source_at_location var:location;
		ask myself {
			do remove_intention(find_ressources, false);
		}
	}
	rule belief: source_location new_desire: has_ressources strength: 2.0;
	rule belief: has_ressources new_desire: return_ressources strength: 3.0;
	
		
	plan letsWander intention:find_ressources 
	{
		do wander;
	}
	
	plan getRessources intention:has_ressources 
	{
		if (target = nil) {
			do add_subintention(has_ressources ,choose_source, true);
			do current_intention_on_hold();
		} else {
			do goto target: target ;
			if (target = location)  {
				sources current_source<- sources first_with (target = each.location);
				if current_source.current_ressources > 0 {
				 	do add_belief(has_ressources);
					ask current_source {current_ressources <- current_ressources - 1;}
					carriage <- carriage  +1;	
				} else {
					do add_belief(new_predicate(empty_source_location, ["location_value"::target]));
				}
				target <- nil;
			}
		}	
	}
	
	plan choose_closest_goldmine intention: choose_source instantaneous: true{
		list<point> possible_sources <- get_beliefs_with_name(source_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		list<point> empty_sources <- get_beliefs_with_name(empty_source_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		possible_sources <- possible_sources - empty_sources;
		if (empty(possible_sources)) {
			do remove_intention(has_ressources, true); 
		} else {
			target <- (possible_sources with_min_of (each distance_to self)).location;
		}
		do remove_intention(choose_source, true); 
	}
	
	plan return_to_base intention: return_ressources {
		do goto target: spawn ;
		if (spawn.location = location)  {
			do remove_belief(has_ressources);
			do remove_intention(return_ressources, true);
			ask spawn {current_riches <- current_riches + myself.carriage;}
			carriage <- 0;
		}
	}
	
	plan return_to_base intention: need_power{
		do goto target: spawn ;
		if (spawn.location = location)  {
			do remove_intention(need_power);
			do remove_belief(need_power);
			current_power <- max_power;
			if(carriage > 0){
				ask spawn {current_riches <- current_riches + myself.carriage;}
				carriage <- 0.0;
			}
		}
	}
	
	reflex live{
		current_power <- current_power -0.1;
	}
	
	reflex power_maintenance when: current_power <= max_power/2{
		do current_intention_on_hold();
		do add_belief(need_power);
		do add_intention(need_power);					
	}
	
	reflex out_of_power when:current_power <=0 {
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

/*species alt_agent skills:[moving]{
	float speed <- 0.03 + rnd(0.001);	
	bool carry;
	float current_power;
	agent my_source;

	reflex move when: my_source != nil {
		if(carry = false){
			path p <- self goto[target::my_source, return_path:: true];
		}
		else{
			path p <- self goto[target::spawn, return_path:: true];
		}
		
		
		
		if(location = my_source.location){
			carry <- true;
			ask sources at_distance 0.05{
				do get_ressources;
			}
		}
		else if(location = spawn.location){
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
		geometry cone <- cone(0,45);
		draw cone(0.1,1.0);
		//draw 0.01 around circle(0.1);
		draw string(current_power with_precision 2) size: 3 color: #black ;
	}
}*/

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