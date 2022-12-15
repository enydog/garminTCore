import Toybox.Activity;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.SensorHistory;
import Toybox.Lang;
import Toybox.Time;
using Toybox.UserProfile as UserProfile;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
import Toybox.Math;
import Toybox.System;

class TCoreGDMView extends WatchUi.DataField {


    enum {
        HEARTRATE,
        TEMPERATURE,
        PRESSURE,
        ELEVATION
    }

    hidden var mValue as Numeric;
    hidden var temp = 0.0;    
    hidden var NMED="BASAL";   
    hidden var IM="IM Target";
    hidden var HIM="70.3 Target";
    hidden var OL="OL Target";   
    hidden var Z1="Z1 Target";       
    hidden var minHRenabled = 90;     
    hidden var olTarget = 2.7;         
    hidden var himTarget = 2.3;         
    hidden var imTarget  = 2.1;                 
    hidden var z1Target  = 1.7;             

    function initialize() {
		var profile = UserProfile.getProfile();
 		var userAge = Gregorian.info(Time.now(), Time.FORMAT_SHORT).year - profile.birthYear;
		var maxHr = 208 - 0.7 * userAge;

        DataField.initialize();
        mValue = 0.0f;
    }


    function calcNullable(nullableValue, defaultValue) {
	   if (nullableValue != null) {
	   	return nullableValue;
	   } else {
	   	return defaultValue;
   	   }	
	  }


    hidden function abso(a,b) {
      if (a>b) {
       return a-b;
      } 
      else {
        return b-a;        
      }
    }

    hidden var alpha           = 0.5; //Default Inertia 

    hidden function inertiaCoef(t) {
      if (t>(basal-3)) 
       {return 0.5;}
      else
       { return 0.7;}      
    }

    hidden var smoothed        = 0.0;
    hidden var lastsmoothed    = 0.0;    
    hidden function tempInertia(num,t) {
     smoothed = inertiaCoef(t) * num + (1-inertiaCoef(t)) * lastsmoothed;
     lastsmoothed = smoothed;
     return smoothed;
    }

  	hidden var cts = 36.0;
	  hidden var basal = cts;	    
	  hidden var al = 1.0;
	  hidden var gamma = 18.88 * 18.88;
    hidden var b0= -7887.1;
    hidden var b1= 384.4286;
    hidden var b2= -4.5714;
    hidden var sigma= 18.80 * 18.80;
    hidden var x_pred = 0.0;
    hidden var v_pred = 0.0;       
    hidden var c_vc = 0.0;
    hidden var k = 0.0;
    hidden var x = 0.0;
    hidden var v = 0.0;

    //hr = heartrate 1hz and t=temperature
    hidden function calcTCore(hr,t)  {
        x=cts;
        x_pred = al * x;
        v_pred = (al  * al ) * (v + gamma);
        c_vc   = 2.0 *  b2 * x_pred + b1;
        k      = (v_pred * c_vc) / ( (c_vc * c_vc) * v_pred + sigma );
        x      = x_pred+k * ( hr- (b2 * (x_pred * x_pred) + b1 * x_pred + b0) );
        v      = ( 1-k * c_vc ) * v_pred;
        cts    = x + ( t * inertiaCoef(t)/100 );
        if(hr>minHRenabled){
          return tempInertia(cts,t);
        } else 
        {
           cts=basal;
           return cts; 
        }  

    }

    hidden function ShowTCore(tc) {
     if (tc==basal) {
      return NMED;  
     }   
     else if (tc < z1Target) {
       return Z1;
      } 
     else if (tc < imTarget) {
       return IM;
      } 
      else if (tc < himTarget) {
        return HIM;        
      }
      else {return OL;}
    }


    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label");
            labelView.locY = labelView.locY - 20;
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 7;
        }

        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().


    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        mValue = calcTCore(calcNullable(info.currentHeartRate, 0),0);
    }


    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color

        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var value  = View.findDrawableById("value") as Text;
        if(mValue<38){
          value.setColor(Graphics.COLOR_DK_GREEN);             
        } else {
          value.setColor(Graphics.COLOR_RED);     
        }
        value.setText(mValue.format("%.2f"));
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
