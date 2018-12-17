/***
* Name: Altruism
* Author: Foug
* Description: no
* Tags: Tag1, Tag2, TagN
***/

model Altruism

/* Insert your model definition here */

global {
	file shape_file_walls <- file("../includes/please4.shp");
	geometry shape <- envelope(shape_file_walls);
	float max_power <- 10.0;
	float max_ressources <- 100.0;
	spawn_point spawn;
	sources source;
	
	int initNumberOfAgents <- 5;
	int numberOfSources <- 1;
	int nbAgents -> {length(alt_agent)};
	
	init{
		create walls from:shape_file_walls;
		create spawn_point{
			spawn <- self;
			location <- {0.3,0.4};
			current_riches <-0.0;
		}
		create sources {
			source <- self;
			location <- {1.1, 0.4};
			current_ressources <- max_ressources;
		}

		create alt_agent number:initNumberOfAgents {
			location <-  spawn.location;
			altruist <- false;
			carry <- false;
			ready <- 0;
			satisfaction <- 0.0;
		}			
	}
	
	reflex end_simulation when: spawn.current_riches >= (numberOfSources * max_ressources){
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
}

species walls {
	aspect base{
		draw shape color:rgb("gray");
	}
}

species alt_agent skills:[moving] control:simple_bdi{
	float speed <- 0.03 + rnd(0.005);
	int ready;
	bool carry;

	float v<-0.0;
	float satisfaction<-0.0;
	float alpha<-0.5;
	float pMax<-127.0;
	float currentPos;
	float oldPos;
	bool blocked;
	bool altruist;
	string currentTask;
	float targetAngle;
	float distance_to_intercept <- 10.0;
	float interactiveSatisfaction<-0.0;
	float initialInsatisfaction<-0.0;
	
	reflex updateSatisfaction when: ready != 0 {
		do resetBlocked;
		do updateV;
		do updateP;
		do seeInteractiveSat;
		do selectBestAction;
	}
	
	action resetBlocked{
		blocked<-false;
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
		//do isBlocked;
		if(blocked){
			v<-(-1.5);
		}
		else{
			v<-0.5+cos(targetAngle);
		}
	}
	
	/* 
	action isBlocked{
		if(currentTask="move"){
			if(currentPos=oldPos){
				blocked<-true;
			}
		}
		else{
			blocked<-false;
		}
	}*/
	
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
	
	
	reflex spreadSatisfaction when: ready != 0{
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
		do moveForward;
	}
	
	action dropOutTask{
		do moveBackward;
	}
	
	action moveForward{
		if(carry = false){
			path p <- self goto[target::source, return_path:: true];
		}
		else{
			path p <- self goto[target::spawn, return_path:: true];
		}
		
	}
	
	action moveBackward{
		if(carry = false){
			path p <- self goto[target::source, return_path:: true];
		}
		else{
			path p <- self goto[target::spawn, return_path:: true];
		}
	}
	


	reflex findSource{
		if(flip(0.01)){
			ready <- 1;
		}
	}
	reflex updateGoals when: ready != 0 {
		if(location = source.location){
			carry <- true;
			ask sources at_distance 0.05{
				do get_ressources;
			}
		}
		else if(location = spawn.location){
			carry <- false;
			ask spawn_point{
				do add_ressources;
			}
		}
	}
	

	
	perceive target:walls in:0.04{
		point wp <- location;
		walls w <- self;
		//highlight(w);
		if(myself.carry = false and (self.location.x > myself.location.x)){
			myself.blocked <- true;
		}
		else if(myself.carry = true and (self.location.x < myself.location.x)){
			myself.blocked <- true;
		}
	}
	
	perceive target:alt_agent in:0.04 when: sum(alt_agent collect each.ready) >= 2{
		if(self != myself and self.location != spawn.location and myself.location != spawn.location){
			if((self.carry = true and myself.carry = false) and (self.location.x > myself.location.x)){
				myself.blocked <- true;
				do goto target:{myself.location.x + 0.2, myself.location.y};
			}
			else if((self.carry = false and myself.carry = true) and (self.location.x < myself.location.x)){
				myself.blocked <- true;
				do goto target:{myself.location.x - 0.2, myself.location.y};
			}
			
		}
		
	}
	
		
	aspect circle{
		draw circle(0.03) color:rgb("green");
		draw 0.005 around circle(0.04);
		draw string(satisfaction with_precision 2) size: 3 color: #black ;
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
		monitor "Number of agents" value: nbAgents ;	
	}	
}