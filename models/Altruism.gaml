/***
* Name: Altruism
* Author: Foug
* Description: no
* Tags: Tag1, Tag2, TagN
***/

/* https://github.com/gama-platform/gama/wiki/BasicProgrammingConceptsInGAML#loop*/

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
	
	float v<-0.0;
	float satisfaction<-0.0;
	float alpha<-0.5;
	float pMax<-127;
	float currentPos;
	float oldPos;
	bool blocked;
	bool altruist;
	string currentTask;
	float targetAngle;
	float distance_to_intercept <- 10.0;
	float interactiveSatisfaction<-0.0;
	float initialInsatisfaction<-0.0;
	
	reflex updateSatisfaction  {
		do updateV;
		do updateP;
		do seeInteractiveSat;
		do selectBestAction;
	}
	
		action updateP{
		satisfaction<-satisfaction+v;
		if(satisfaction>pMax){
			satisfaction<-pMax;
		}
		if(satisfaction<(-pMax)){
			satisfaction<-(-pMax);
		}
	}
	action updateV{
		do isBlocked;
		if(currentTask="move"){
			if(blocked){
				v<-(-1.5);
			}
			else{
				v<-0.5+cos(targetAngle);
			}
		}
	}
	
	action isBlocked{
		if(currentTask="move"){
			if(currentPos=oldPos){
				blocked<-true;
			}
		}
		else{
			blocked<-false;
		}
	}
	
	action selectBestAction{
		if(altruist){
			do dropOutTask;
		}
		else{
			if(satisfaction>=0){
				do keepTask;
			}
			else{
				do dropOutTask;
			}
		}
	}
	
	action seeInteractiveSat {
		if (interactiveSatisfaction>satisfaction){
			altruist<-true;
		}
		else {
			altruist<-false;
		}
	}
	
	
	reflex spreadSatisfaction{
		float spreadSat<-0.0;
		if(altruist){
			spreadSat<-interactiveSatisfaction;
		}
		else{
			spreadSat<-self.satisfaction;
		}
		ask alt_agent at_distance(distance_to_intercept) {
			if(alpha*abs(spreadSat) > (1-alpha)*abs(myself.satisfaction)){
				if(myself.interactiveSatisfaction< alpha*abs(self.satisfaction)){
					myself.interactiveSatisfaction<-spreadSat*alpha;
				}
			}
		}
	}

	
	action keepTask{
		if(currentTask="move"){
			do moveForward;
		}
	}
	
	action dropOutTask{
		if(currentTask="move"){
			do moveBackward;
		}
	}
	
	action moveForward{
		
	}
	
	action moveBackward{
		
	}
	
	
	reflex move when: the_target != nil {
		currentTask<-"move";
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