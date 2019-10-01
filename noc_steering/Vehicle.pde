// Seek_Arrive
// Daniel Shiffman <http://www.shiffman.net>

// The "Vehicle" class

//decision making - Paul May

class Vehicle {
  ArrayList<Something> knownThreats = new ArrayList();
  ArrayList<Something> knownFood = new ArrayList();

  PVector location;
  PVector velocity;
  PVector acceleration;
  float r;
  float d = conf.bound;
  float wandertheta;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  color moodColour; //an indicator of my mood
  String flag; //the little text indicator beside me
  color edgeColour;
  boolean fleeing; //am I running away
  boolean seeking; //am I currently dealing with an object

  //forces
  float flee_maxspeed = 10;
  float flee_maxforce = 1;
  float seek_maxspeed = 4; //can we change this based on how much feeding the creature has done?
  float seek_maxforce = 0.1; //
  float arrive_maxspeed = 1;
  float arrive_maxforce = 0.05;


  Vehicle(float x, float y) {
    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    location = new PVector(x, y);
    r = 2.0;
    maxspeed = seek_maxspeed;
    maxforce = seek_maxforce;
    flag = "?";
  }



  // Method to update location
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    location.add(velocity);
    // Reset accelerationelertion to 0 each cycle
    acceleration.mult(0);
  }



  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }



  // A method that calculates a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  void seek(PVector _target) {
    PVector desired = PVector.sub(_target, location);  // A vector pointing from the location to the target
    
    // Normalize desired and scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);
    
    // Steering = Desired minus velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    applyForce(steer);
  }


  void flee(PVector _target) {
    PVector desired = PVector.sub(_target, location);  // A vector pointing from the location to the target
    
    // Normalize desired and scale to maximum speed
    desired.normalize();
    desired.mult(-1*maxspeed);
    
    // Steering = Desired minus velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    applyForce(steer);
  }

  //wander around the place
  void wander() {
    float wanderR = 25;         // Radius for our "wander circle"
    float wanderD = 40;         // Distance for our "wander circle"
    float change = 0.3;
    wandertheta += random(-change, change);     // Randomly change wander theta
    
    // Now we have to calculate the new location to steer towards on the wander circle
    PVector circleloc = velocity.get();    // Start with velocity
    circleloc.normalize();            // Normalize to get heading
    circleloc.mult(wanderD);          // Multiply by distance
    circleloc.add(location);               // Make it relative to boid's location
    float h = velocity.heading2D();        // We need to know the heading to offset wandertheta
    PVector circleOffSet = new PVector(wanderR*cos(wandertheta+h), wanderR*sin(wandertheta+h));
    PVector target = PVector.add(circleloc, circleOffSet);
    seek(target);
  }  

  void arrive(PVector _target) {
    PVector desired = PVector.sub(_target, location);  // A vector pointing from the location to the target
    float d = desired.mag();
    
    // Normalize desired and scale with arbitrary damping within 100 pixels
    desired.normalize();
    float m = map(d, 0, 100, 0, maxspeed);
    desired.mult(m);
    
    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    applyForce(steer);
  }


  //what behaviour should I carry out based on the location and type of object?

  void decide() {
    //need to add a way to only be under the influence of one object
    for (Something _s:allThings) {
      //how far am I from the Something
      float targetDistance = dist(location.x, location.y, _s.location.x, _s.location.y);
      // println(targetDistance);
      //if I'm out of range just wander
      if (targetDistance>conf.scent_r || _s.alive == false) {
        fleeing = false;
        maxspeed = seek_maxspeed; 
        maxforce = seek_maxforce;
        //indicate our state
        moodColour = colours[1];
        flag = "w";
        wander();
      }
      else if (targetDistance>conf.sight_r && targetDistance < conf.scent_r && fleeing == false) {
        //change the speed of approach if we're within visual range
        if (knownThreats.indexOf(_s) < 0) {
          //this isn't on our list of threats
          maxspeed = seek_maxspeed; 
          maxforce = seek_maxforce;
          moodColour = colours[6];
          flag = "?";
          seek(_s.location);
        }
        else {
          //we already know this is a threat
          fleeing = true;
          maxspeed = flee_maxspeed;
          maxforce = flee_maxforce;
          flee(_s.location);
        }
      }
      else {
        if (_s.alive == true) {
          if (_s.threat == true) {
            flag = "t";
            moodColour = colours[7];
            if (knownThreats.indexOf(_s) < 0) {
              knownThreats.add(_s);
            };
            //println("run away");
            fleeing = true;
            maxspeed = flee_maxspeed;
            maxforce = flee_maxforce;
            flee(_s.location);
          }
          else {
            //it's food - yay!
            flag = "f";
            if (knownFood.indexOf(_s) < 0) {
              knownFood.add(_s);
            };
            maxspeed =  arrive_maxspeed;
            maxforce =  arrive_maxforce = 0.05;
            println("food");
            arrive(_s.location);
            _s.deplete(); //eat some food
          }
          //if it's food, arrive and feed
        }
      }
    }
  }


  void boundaries() {
    //there must less verbose way of doing this - like distance from the center or something?
    PVector desired = null;

    if (location.x < d) {
      flag = "!";
      desired = new PVector(maxspeed, velocity.y);
    } 
    else if (location.x > width -d) {
      flag = "!";
      desired = new PVector(-maxspeed, velocity.y);
    } 

    if (location.y < d) {
      flag = "!";
      desired = new PVector(velocity.x, maxspeed);
    } 
    else if (location.y > height-d) {
      flag = "!";
      desired = new PVector(velocity.x, -maxspeed);
    } 

    if (desired != null) {
      desired.normalize();
      desired.mult(maxspeed);
      PVector steer = PVector.sub(desired, velocity);
      steer.limit(maxforce);
      applyForce(steer);
    }
  }  


  void display() {

    //a little visual indicator to show what the vehicle is doing, nicer than println

    fill(0);
    textFont(helv, 12);
    text(flag, location.x+15, location.y-10);
    textFont(helv, 14);
    //how many threats do I know about
    String threatChit = "";
    String foodChit="";
    for (int i=0;i<knownThreats.size();i++) {
      threatChit+="•";
    }
    for (int i=0;i<knownFood.size();i++) {
      foodChit+="•";
    }


    fill(colours[7]); //red
    text(threatChit, location.x+25, location.y-10);
    fill(colours[6]); //green
    text(foodChit, location.x+30, location.y-10);

    beginShape();
    stroke(0);
    endShape();
    // Draw a triangle rotated in the direction of velocity
    float theta = velocity.heading2D() + PI/2;
    fill(moodColour);
    stroke(100);
    pushMatrix();
    translate(location.x, location.y);
    stroke(colours[2]);
    rotate(theta);
    beginShape();
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape(CLOSE);
    popMatrix();
  }
}

