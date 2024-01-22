//
//

const dataTable = document.getElementById('data-table');
const dataTableBody = document.getElementById('data');
const dataVisualization = document.getElementById('data-visualization');
const search_field = document.getElementById('search'); 

const lineHigh = 16; 
const blockMultiplier = 10;

var lineNumber = 1; 
var WindowWidth = window.innerWidth;

var gX = 0; // current X and Y cordinates for box&text
var gY = 0; //    adjusted for each new box or line 

function  debug (outtext) {
  const timestamp = new Date().toISOString().split('.')[0];
  const linebreak = '<br>';
  document.getElementById('debug').innerHTML += `${timestamp} ${outtext}${linebreak}`;
}

// thank youe Brendan Gregg
function s(info) { document.getElementById('search').value = info; search (); console.log(search_field.NodeValue); }
function c() { document.getElementById('search').value = '' ; search(); }

function RGBattribute(objID) {
  const clr = objID % ( 2 ** 24) ; // we can use only 3 byte - 1 for each color
  const R = clr >> 16;
  const G = (clr >> 8 ) % ( 2 ** 8 ); 
  const B = clr % ( 2 ** 8 ); 
  return 'rgb(' + R + ',' + G + ',' + B + ')';
}

function RGBtextAttribute(objID) {
  const clr = objID % ( 2 ** 24) ; // we can use only 3 byte - 1 for each color
  const R = ( clr >> 16 ) ^ 255;
  const G = ( (clr >> 8 ) % ( 2 ** 8 ) ) ^ 255; 
  const B = ( clr % ( 2 ** 8 ) ) ^255; 
  return 'rgb(' + R + ',' + G + ',' + B + ')';
}

// increases SVG high if the blockID does not (yet) fit
//  - based on lineHigh and blockMultiplier
function SVGadjustHeight(blockPosition) {
  const SVGcurrentHeight = dataVisualization.getAttribute('height');
  const SVGCurrentWidth = dataVisualization.getAttribute('width');
  const SVGcurrentRows =  Math.floor(SVGcurrentHeight / lineHigh); 
  const reqRows = Math.ceil( (blockPosition * blockMultiplier) / SVGCurrentWidth);
  if ( reqRows > SVGcurrentRows) {
    debug( "pos: " + blockPosition + " H: " + SVGcurrentHeight + " W: "+ SVGCurrentWidth + "cR: " + SVGcurrentRows + " rR: " + reqRows)
    dataVisualization.setAttribute('height', (reqRows +1 ) * lineHigh) ;
  }
}

// 1 character ~ 8 pixel at font size 12; Verdana
function shrinkText(inText, width){
  const charPixel = 8;
//  debug('shrinkText: ' + inText + " inText.length: " + inText.length + " width/8: " + Math.floor(width/charPixel) ) ;
  var myText = inText;
  if ( inText.length < (width / charPixel ) ) {
    return myText; 
  } else {
    if( myText.includes('.') ) { // remove schema
      myText = shrinkText(myText.substring(myText.indexOf('.')+1 )  , width);
    }
    if ( myText.includes(':') ){ // remove blocks
      myText = shrinkText(myText.substring(0, myText.indexOf(':')-1 ) , width);   
    }
    if ( myText.length > (width / charPixel ) ) { // remove some characters
//      debug('shrinkText: still bigger than expected: ' + myText)
      myText = myText.substring(0,Math.floor(width / charPixel ));
    }

  }

  return myText;  
}

function drawBox(x, y, width, id, name) {
  const group = document.createElementNS('http://www.w3.org/2000/svg', 'g');
  const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
  const box = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
  const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');

  group.setAttribute('class',id); 
  title.innerHTML = name;

//  text.innerHTML = id;
  text.innerHTML = shrinkText(name, width);
  text.setAttribute('font-size',"12");
  text.setAttribute('font-family',"Verdana");

  box.setAttribute('x',  x );
  box.setAttribute('y',  y) ;
  text.setAttribute('x', x );
  text.setAttribute('y', y + 11 );
  text.setAttribute('fill', RGBtextAttribute(id)); 
//  text.setAttribute('stroke', 'black'); // looks ugly! 

  box.setAttribute('width', width);
  box.setAttribute('height', 15);
  box.setAttribute('fill', RGBattribute(id) );
  group.setAttribute('onmouseover',"s(" + id + ")" ) ; 
  group.setAttribute('onmouseout',"c()" );
  group.setAttribute('class', 'func_g')

  group.append(title);
  group.append(box);
  group.append(text);
  dataVisualization.appendChild(group);
}

function tryBox(x, y, width, id, name) {
  if ( ( x + width ) <= WindowWidth ) {
    drawBox (x, y, width, id, name);
  } else {
    drawBox (x, y, WindowWidth - x, id, name );
    tryBox( 0, y + lineHigh, width - (WindowWidth - x), id, name);
  }
}

const createBox = (dataRow) => {
  const owner = dataRow.querySelector('td:nth-child(1)').textContent;
  const segmentName = dataRow.querySelector('td:nth-child(2)').textContent;
  const partitionName = dataRow.querySelector('td:nth-child(3)').textContent;
  const blockID = Number(dataRow.querySelector('td:nth-child(8)').textContent);
  const blockCount = Number(dataRow.querySelector('td:nth-child(10)').textContent);
  const objID = Number(dataRow.querySelector('td:nth-child(12)').textContent);
  var obName = "";
//  debug(owner + '.'+ segmentName + "["+partitionName + "] : "+ blockCount);
//  debug(segmentName + ' - ' + partitionName + ' ~ ' + gX);

  // make sure the current extent will fit into the SVG  
  SVGadjustHeight(blockID + blockCount);

  const partIsNBSP = partitionName.includes("&nbsp;");
  if ( !partIsNBSP) {
     obName = owner + '.'+ segmentName + " : "+ blockCount;
  } else {
     obName = owner + '.'+ segmentName + "["+partitionName + "] : "+ blockCount;
  }

  tryBox( (blockID *blockMultiplier ) % WindowWidth 
         , Math.ceil( (blockID *blockMultiplier ) / WindowWidth ) * lineHigh
         , blockCount * blockMultiplier
         , objID
         , obName);
};

// Load the data from the table into the visualization
dataVisualization.dataset = {};
dataVisualization.setAttribute('width', WindowWidth )

for (const row of dataTableBody.querySelectorAll('tr')) {
//	debug(row);
  const dataRow = row.querySelectorAll('td');
  const owner = dataRow[0].textContent;
  const segmentName = dataRow[1].textContent;
//  	debug("1 " + dataRow[1].textContent);

  //if (!dataVisualization.dataset[owner]) {
  //  dataVisualization.dataset[owner] = {};
  //}

//  if (!dataVisualization.dataset[owner][segmentName]) {
//    dataVisualization.dataset[owner][segmentName] = '';
//  }

  createBox(row);
}
