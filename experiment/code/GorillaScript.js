//-------------------
// REQUIRED VARIABLES
//-------------------
// DISPLAY NAMES AND SCREEN NUMBERS
// In this variable, list the names of the displays where the count up functionality is required
var _countUpDisplays: string[] = ['trial'];
// Give the screen index for the screen where this functionality is required
// NB at the moment this MUST be the same index in each display
var _countUpScreenIndex: number = 1;

// EMBEDDED DATA KEYS
// This variable is the key we will use to store the end value of the countUp
//var _countUpEndValueKey: string = 'finalCount';

// ZONE NAMES
// This variable gives the name of the zone where you want the count to be displayed
var _countUpZoneName: string = 'stimzone';

// COUNTING SETTINGS
// This variable sets the maximum length of the count up before we automatically end the screen
// This is a value in milliseconds, ms
var _countMax: number = 12000;

// This variables sets the interval for the setInterval - the number of milliseconds between executions of the callback function
// Setting this too low will cause the setInterval to lock up the execution thread.  Be cautious going below 5ms.
// Also, bare in mind that the average monitor, running at 60Hz, will only update once every 16ms anyway.  Setting the interval to a low value
// will not, bluntly put, make the numbers go up to a finer level on the screen!
// Finally, setting the interval value to something like 7 or 8 renders a more convincing countup than 10 or 5
// It looks like there is more variability in the digits when using a number that, when added to itself, creates more variation
var _countInterval: number = 100;

// OTHER SCRIPT VARIABLES - This do not require editing
// This variable stores a reference to the interval timer
// We'll use it to clear the time onScreenFinish
var _countIntervalID = null;
// This variable will store our current count
// It needs to be global so we can access it from onScreenFinish
var _countValue: number = 0;

/******************************************************************************
 * USER SETTINGS
 *****************************************************************************/

// Display names & screen indices
// Remember, screen index starts at 0!

// Display name where answer is recorded
var TRIAL_DISPLAY = 'trial';

// Screen index where answer is recorded
var TRIAL_SCREEN = 1;

// Display name where bonus is shown
var BONUS_DISPLAY = 'bonus';

// Screen index where bonus is shown
var BONUS_SCREEN = 0;

var BONUS_END_DISPLAY = 'endbonus';

var BONUS_END_SCREEN = 0;

/*//24 Trials
var numTrials = 4;
var numBlocks = 6;
var block = 0;
var practTrials = 2;*/

/*//60 Trials
var numTrials = 10;
var numBlocks = 6;
var block = 0;
var practTrials = 10;*/

//300 Trials
var numTrials = 50;
var numBlocks = 6;
var block = 0;
var practTrials = 10;


// ----------------------------------------------------------------------------

// Other vars

// Name of embedded variable where response is stored; this is set under
// Task Structure on display TRIAL_DISPLAY and screen TRIAL_SCREEN
var EMBEDDED_RESPONSE = 'responseVar';

/******************************************************************************
 * Helper Functions
 *****************************************************************************/
var myrng = new Math.seedrandom(Date.now());

function playMachine(machine) {
    var mean;
    let sd = 2;
    switch (machine) {
        case "1":
            mean = -2;
            break;
        case "2":
            mean = -1;
            break;
        case "3":
            mean = 0;
            break;
        case "4":
            mean = 1;
            break;
        case "5":
            mean = 2;
            break;
    }
    console.log("mean " + mean);
    console.log("machine " + machine);
    return gaussianRandom(mean, sd)
}

function gaussianRandom(mean = 0, stdev = 1) {
    const u = 1 - myrng(); // Converting [0,1) to (0,1]
    const v = myrng();
    const z = Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
    // Transform to the desired mean and standard deviation:
    return z * stdev + mean;
}

function trialSample(rangeMin, rangeMax, numSamples) {
    var sampleArray = [];
    while (sampleArray.length < numSamples) {
        var randSample = Math.floor(myrng() * (rangeMax - rangeMin + 1)) + rangeMin;
        console.log("sample trial " + randSample);
        if (!sampleArray.includes(randSample)) {
            sampleArray.push(randSample);
        }
    }
    return sampleArray;
}

function format(display, block){
            var results = `<span class="centered">
            <p style="font-size: 24px">
            Congratulations! You have finished block ${block}. Here are your results from the chosen trials:</p>`;
            for(let object of display){
                let decision;
                if (object.decision == false) {
                    decision = "You timed out";
                } else {
                    decision = `You answered ${object.decision}`;
                }
                results += `<p>Trial ${object.trial_number}: ${decision}, $${object.payoff.toFixed(2)}</p>`;
            }
            results += `</span>`;
            return results;
        } 

function formatEnd(sum){
            return `<span class="centered">
            <p style="font-size: 24px">
            Congratulations! You have finished the experiment. Here is your final bonus:</p>
            <p>US $${sum.toFixed(2)}</p>
            <p> Note: If your final bonus is negative you will not receive a bonus. </p>
            </span>`;
        } 

function roundTo(num, places=2) {
  // Round a number `num` to `places` decimal places
  return Math.round(num * 10 ** places) / 10 ** places;
}
                

// On Screen Start Hook
gorillaTaskBuilder.onScreenStart((spreadsheet: any, rowIndex: number, screenIndex: number, row: any, container: string) => {
    if (row.display == BONUS_END_DISPLAY && screenIndex == BONUS_END_SCREEN) {
        
        // create an array
        var fullTotal = gorilla.retrieve("fullTotal", [], true);

        // create a variable for the sum and initialize it
        let sum = 0;

        // iterate over each item in the array
        for (let i = 0; i < fullTotal.length; i++ ) {
            sum += fullTotal[i];
        }

        $(container + ' .content').html(formatEnd(sum));
        //replicate this for end bonus screen
        
        gorilla.metric({
            response_type: 'Bonus Total',
            response: sum
        });

        gorilla.refreshLayout();

    }
    // Select random bonus and display result at end of task
    if (row.display == BONUS_DISPLAY && screenIndex == BONUS_SCREEN) {
        block += 1;
        var randSample = 0;
        var allResponses = gorilla.retrieve('allResponses', [], true);
        var allMachines = gorilla.retrieve('allMachines', [], true);
        //pull 2 random trials
        var min = (block * numTrials) - (numTrials - 1) + practTrials - 1;
        var max = (block * numTrials) + practTrials - 1;
        sampleArray = trialSample(min, max, 2);
        //check if they said yes or no for each
        var Total = 0;
        var blockDisplays=[];
        for (let trial of sampleArray) {
            var object = {
                trial_number: trial + 1 - practTrials,
                decision: allResponses[trial],
                payoff: 0
            };
            if (allResponses[trial] == "YES") {
                var output = playMachine(allMachines[trial]);
                object.payoff = roundTo(output, 2);
                console.log("object.payoff " + object.payoff);
                Total += object.payoff;
            }
            blockDisplays.push(object);
            gorilla.metric({
                response_type: 'Bonus Trial',
                response: trial
            });
            gorilla.metric({
                response_type: 'Bonus Payoff',
                response: object.payoff
            });
        }
        
        var allDisplays = gorilla.retrieve('allDisplays', [], true);
        allDisplays.push(blockDisplays);
        gorilla.store('allDisplays', allDisplays, true);
        
        var fullTotal = gorilla.retrieve('fullTotal', [], true);
        fullTotal.push(Total);
        gorilla.store('fullTotal', fullTotal, true);

        $(container + ' .content').html(format(blockDisplays, block));
        //replicate this for end bonus screen
        
        gorilla.refreshLayout();
    }
    // Check to see if we're on the display and screen where we want to alter the functionality
    _countValue = 0;
    var countStim = 1;
    if (_countUpDisplays.includes(row.display) && screenIndex == _countUpScreenIndex) {
        //parsing out stim column values
        var size = row.size;
        var color = row.color;
        var sizeArray = size.split('", "'); // Splitting 'stimuli' string into an array************
        var colorArray = color.split('", "');
        // Make sure our count starts at zero

        // setInterval allows you to repeatly call an assigned function every X ms
        // This functionality works asynchronously - other process can continue in the background in between setIntervals executions
        // The function itself returns an ID, which can be used to access the interval and, importantly, end it
        // On Screen Start Hook
        _countIntervalID = setInterval(() => {
            // If we've exceeded our max count, we now need to end the interval and the screen
            if (_countValue >= ((_countMax / _countInterval) / 3)) {
                // Using the ID we saved earlier, clearInterval will stop the interval 
                clearInterval(_countIntervalID);
                _countIntervalID = null;
                gorillaTaskBuilder.forceAdvance(false, true, { go_to_screen: "faster" });
            } else {
                // Update our current countValue and add it to the screen
                // We use .toFixed to give us a fixed number of decimal places

                if (countStim < 3) {
                    countStim += 1;
                    var dotsize = sizeArray[_countValue];
                    var dotcolor = colorArray[_countValue];
                } else {
                    var dotsize = 0;
                    var dotcolor = "#FFFFFF";
                    countStim = 1;
                    _countValue += 1;
                }

                $('#gorilla').hide();

                //Update the html source
                var style = `font-size: ${dotsize}px; color: #${dotcolor}; text-align: center; 
                    position: relative; top: 50%; margin: auto; font-family: monospace; line-height: 0;`;
                $(container).find(`[data-tag='stimzone']`).html('•').attr('style', style);

                $('#gorilla').show();
                gorilla.refreshLayout();
            }

        }
            , _countInterval);
    }
});

gorillaTaskBuilder.onScreenFinish((spreadsheet: any, rowIndex: number, screenIndex: number, row: any, container: string, correct: boolean) => {
    clearInterval(_countIntervalID);
    // Store each response at the end of the response screen
    if (row.display == TRIAL_DISPLAY && screenIndex == TRIAL_SCREEN) {
        var lastResponse = gorilla.retrieve(EMBEDDED_RESPONSE, null, true);
        console.log("response " + lastResponse);
        var allResponses = gorilla.retrieve('allResponses', [], true);
        allResponses.push(lastResponse);
        gorilla.store('allResponses', allResponses, true);
        var allMachines = gorilla.retrieve('allMachines', [], true);
        allMachines.push(row.s);
        gorilla.store('allMachines', allMachines, true);
    }

});