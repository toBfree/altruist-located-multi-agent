/***
* Name: Altruism
* Author: Foug
* Description: no
* Tags: Tag1, Tag2, TagN
***/

model Altruism

/* Insert your model definition here */

global {
	geometry shape <- envelope(square(500));
	init{
		create spawn_point{
			p <- {100,100};
			location <- p;
		}
		create sources number:5;
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
		draw square(50) color:rgb("gray");
	}
}

species sources {
	point p;
	
	aspect square{
		draw square(25) color:rgb("red");
	}
}

species walls {
	aspect square{
		draw square(25) color:rgb("gray");
	}
}

species alt_agent skills:[moving]{
	float speed <- 5.0 + rnd(5);
	point the_target;
	point spawning_point;
	bool carry;
	/*reflex move{
		do wander;
	}*/
	
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
		draw circle(5) color:rgb("green");
	}
}

experiment main_experiment type:gui{
	output{
		display map {
			species spawn_point aspect:square;
			species sources aspect:square;
			species alt_agent aspect:circle;	
		}
	}	
}