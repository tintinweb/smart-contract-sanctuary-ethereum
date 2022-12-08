/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

/*

MapElevationStorage deployed and used for Etherias v0.9 through v1.2

Solidity version: 0.1.6-d41f8b7c/.-Emscripten/clang/int linked to libethereum-
compile once with default optimization

var mesAddress = "0x68549D7Dbb7A956f955Ec1263F55494f05972A6b";
var mesAbi = [
	{ "constant": true, "inputs": [], "name": "getElevations", "outputs": [{ "name": "", "type": "uint8[1089]" }], "type": "function", "payable": false, "stateMutability": "view" },
	{ "constant": false,  "inputs": [], "name": "setLocked", "outputs": [], "type": "function", "payable": true, "stateMutability": "payable" },
	{ "constant": true, "inputs": [], "name": "getLocked", "outputs": [{ "name": "", "type": "bool" }], "type": "function", "payable": false, "stateMutability": "view" },
	{ "constant": true, "inputs": [{ "name": "col", "type": "uint8" }, { "name": "row", "type": "uint8" }], "name": "getElevation", "outputs": [{ "name": "", "type": "uint8" }], "type": "function", "payable": false, "stateMutability": "view" },
	{ "constant": false, "inputs": [{ "name": "col", "type": "uint8" }, { "name":  "_elevations", "type": "uint8[33]" }], "name": "initElevations", "outputs": [], "type": "function", "payable": true, "stateMutability": "payable" }, { "type": "fallback", "payable": true, "stateMutability": "payable" }
];
var mes = new web3.eth.Contract(mesAbi, mesAddress);

{
	"4166c1fd": "getElevation(uint8,uint8)",
	"049b7852": "getElevations()",
	"2d49ffcd": "getLocked()",
	"57f10d71": "initElevations(uint8,uint8[33])",
	"10c1952f": "setLocked()" // locking tx: 0xffbac6118d58a286b6e1a5b7d40497e24ca42b95383a1d7783c239ad25aed84e
}

NOTE: JS helper functions at bottom.

*/


contract MapElevationStorage
{
    uint8[1089] elevations; // while this is a [a,b,c,d,a1,b1,c1,d1...] array, it should be thought of as
    // [[a,b,c,d], [a1,b1,c1,d1]...] where each subarray is a column.
    // since you'd access the subarray-style 2D array like this: col, row
    // that means that in the 1D array, the first grouping is the first col. The second grouping is the second col, etc
    // As such, element 1 is equivalent to 0,1 -- element 2 = 0,2 -- element 33 = 1,0 -- element 34 = 1,1
    // this is a bit counter intuitive. You might think it would be arranged first row, second row, etc... but you'd be wrong.
    address creator;
    function MapElevationStorage()
    {
    	creator = msg.sender;
    }
    
    function getElevations() constant returns (uint8[1089])
    {
    	return elevations;
    }
    
    function getElevation(uint8 col, uint8 row) constant returns (uint8)
    {
    	//uint index = col * 33 + row;
    	return elevations[uint(col) * 33 + uint(row)];
    }
    
    function initElevations(uint8 col, uint8[33] _elevations) public 
    {
    	if(locked) // lockout
    		return;
    	uint skip = (uint(col) * 33); // e.g. if row 2, start with element 66
    	uint counter = 0;
    	while(counter < 33)
    	{
    		elevations[counter+skip] = _elevations[counter];
    		counter++;
    	}	
    }
    
    /**********
    Standard lock-kill methods 
    **********/
    bool locked;
    function setLocked()
    {
 	   locked = true;
    }
    function getLocked() public constant returns (bool)
    {
 	   return locked;
    }
    function kill()
    { 
        if (!locked && msg.sender == creator)
            suicide(creator);  // kills this contract and sends remaining funds back to creator
    }
}




/*

doGetElevations prints a console map of elevations. Row 0 is at the bottom. Col 0 is on the left.

function elevationOrPeriod(elevation) {
	if (elevation >= 125)
		return elevation;
	else
		return ".";
}

function getElevation(mycol, myrow) {
	return new Promise((resolve, reject) => {
		mes.methods.getElevation(mycol, myrow).call(function(err, res) {
			resolve([mycol, myrow, res]);
		});
	});
}

var elevations = new Array(33);
function doGetElevations() {
	var c = 0;
	var r = 0;
	var limit = 1089;
	var numReturned = 0;
	var c2 = 0;
	var r2 = 32;
	var rowString = "";
	while (c < 33) {
		r = 0;
		elevations[c] = new Array(33);
		while (r < 33) {
			getElevation(c, r).then(function(resultArray) {
				elevations[resultArray[0]][resultArray[1]] = resultArray[2];
				numReturned++;
				if (numReturned === limit) {
					while (r2 >= 0) {
						c2 = 0
						rowString = "";
						while (c2 < 33) {
							rowString = rowString + elevationOrPeriod(elevations[c2][r2]) + "\t";
							c2++;
						}
						console.log(rowString.substring(0, rowString.length - 1));
						r2--;
					}
				}
			});
			r++;
		}
		c++;
	}
}
doGetElevations();

*/