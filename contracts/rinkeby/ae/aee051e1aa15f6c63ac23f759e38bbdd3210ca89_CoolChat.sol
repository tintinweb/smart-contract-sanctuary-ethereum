/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

pragma solidity ^0.4.0;

contract CoolChat {
	mapping (address => string) 	addrNameMap;
	mapping (string => bool) 		nameUseMap;
    
	string[] articleArray;
	address[] writerArray;
	string[] writerNameArray;


    function getArticleCount() public view returns (uint256 index) {
		return articleArray.length;
	}

	function getArticle(uint256 index) public view returns (address, string memory, string memory) {
		require(index<articleArray.length);
    
		return (writerArray[index], writerNameArray[index], articleArray[index]);
	}

	function addArticle(string memory str) public {
		require(bytes(str).length<=3000);//utf8中文字最多1000字
    	
		articleArray.push(str);
		writerArray.push(msg.sender);
		writerNameArray.push(addrNameMap[msg.sender]);
	}
	
	function testMassArticle(uint256 num) public {
		
		string memory name=addrNameMap[msg.sender];
		string[4] memory strArray=["0", "1", "2", "3"];
		
		for(uint i=0; i<num; i++){
			articleArray.push(strArray[i%4]);
			writerArray.push(msg.sender);
			writerNameArray.push(name);
		}
	}
	
    function isUsedName(string memory name) public view returns (bool) {
		return nameUseMap[name];
	}

    function getWriterName(address addr) public view returns (string memory) {
		return addrNameMap[addr];
	}

	function setWriterName(string memory name) public {
		require(nameUseMap[name]==false);
		require(bytes(name).length<=90);//utf8中文字最多30字
		
		string memory oldName=addrNameMap[msg.sender];
		if(bytes(oldName).length!=0){
			nameUseMap[oldName]=false;
		}
		nameUseMap[name]=true;
		addrNameMap[msg.sender]=name;
	}
}