/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

/*

BlockDefinitionStorage deployed and used for Etherias v1.1 and v1.2

Solidity version: 0.1.6-d41f8b7c/.-Emscripten/clang/int linked to libethereum-
compile once with default optimization

var bdsAddress = 0xd4e686a1fbf1bfe058510f07cd3936d3d5a70589
var bdsAbi = [
	{"constant":true,"inputs":[{"name":"which","type":"uint8"}],"name":"getAttachesto","outputs":[{"name":"","type":"int8[48]"}],"type":"function"},
	{"constant":false,"inputs":[],"name":"setLocked","outputs":[],"type":"function"},
	{"constant":true,"inputs":[{"name":"which","type":"uint8"}],"name":"getOccupies","outputs":[{"name":"","type":"int8[24]"}],"type":"function"},
	{"constant":true,"inputs":[],"name":"getLocked","outputs":[{"name":"","type":"bool"}],"type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"type":"function"},
	{"constant":false,"inputs":[{"name":"which","type":"uint8"},{"name":"attachesto","type":"int8[48]"}],"name":"initAttachesto","outputs":[],"type":"function"},
	{"constant":false,"inputs":[{"name":"which","type":"uint8"},{"name":"occupies","type":"int8[24]"}],"name":"initOccupies","outputs":[],"type":"function"},{"inputs":[],"type":"constructor"}
];
var bds = new web3.eth.Contract(bdsAbi, bdsAddress);

{
    "0878bc51": "getAttachesto(uint8)",
    "2d49ffcd": "getLocked()",
    "1bcf5758": "getOccupies(uint8)",
    "d7f3b73b": "initAttachesto(uint8,int8[3][16])",
    "1256c698": "initOccupies(uint8,int8[3][8])",
    "10c1952f": "setLocked()" // locking tx: 0xa3f2eee428b54928f0c56fdf5b850f901666fc274a5f4524f514d202c788af2e
}

*/

contract BlockDefStorage
{
	bool locked;
	
    Block[32] blocks;
    struct Block
    {
    	int8[24] occupies; // [x0,y0,z0,x1,y1,z1...,x7,y7,z7] 
    	int8[48] attachesto; // [x0,y0,z0,x1,y1,z1...,x15,y15,z15] // first one that is 0,0,0 is the end
    }
    
    function getOccupies(uint8 which) public constant returns (int8[24])
    {
    	return blocks[which].occupies;
    }
    
    function getAttachesto(uint8 which) public constant returns (int8[48])
    {
    	return blocks[which].attachesto;
    }
    
    function getLocked() public constant returns (bool)
    {
    	return locked;
    }
    
    function setLocked() 
    {
    	locked = true; // once set, there is no way to undo this, which prevents reinitialization of Occupies and Attachesto
    }
    
    function initOccupies(uint8 which, int8[3][8] occupies) public 
    {
    	if(locked) // lockout
    		return;
    	uint counter = 0;
    	for(uint8 index = 0; index < 8; index++)
    	{
    		for(uint8 subindex = 0; subindex < 3; subindex++)
        	{
    			blocks[which].occupies[counter] = occupies[index][subindex];
    			counter++;
        	}
    	}	
    }
    
    function initAttachesto(uint8 which, int8[3][16] attachesto) public
    {
    	if(locked) // lockout
    		return;
    	uint counter = 0;
    	for(uint8 index = 0; index <  16; index++)
    	{
    		for(uint8 subindex = 0; subindex < 3; subindex++)
        	{
    			blocks[which].attachesto[counter] = attachesto[index][subindex];
    			counter++;
        	}
    	}	
    }
}