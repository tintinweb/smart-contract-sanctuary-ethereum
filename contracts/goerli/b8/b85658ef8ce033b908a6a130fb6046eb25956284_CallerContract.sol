// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract CallerContract {
	function banchAll(address[] memory _address,address[] memory _nftAddress,uint[] memory values, bytes[] memory data) external{
        for(uint i=0;i<_address.length;i++){
			
			TransactionBatcher(_address[i]).batchSend(_nftAddress[i],values[i],data[i]);
        }

	}

	
}

contract TransactionBatcher{
	function batchSend(address targets, uint values, bytes memory datas) public payable {}
}


    // function batchSend(address targets, uint values, bytes memory datas) public payable {
    
        
    //         (bool success,) = targets.call{value:(values)}(datas);
    //         require(success,"Transaction failed in contract");

    //     emit Done();
    // }


//["0xC4FA8Ef3914b2b09714Ebe35D1Fb101F98aAd13b","0xa9d281dA3B02DF2ffc8A1955c45d801B5726661D","0x77eC7CE5224728226F56f2b33ac9Aa5D0A368018","0xdfA652ba46f72a877500fDaC5b6E212212d53549","0xED2A16AB9a997b9275DA6Ac202a1AE4344569b78","0xD09B3E74Be5895883E96E9Ac4c9Eea95a90fcB49","0x2855F9fdC4aDb2825a7fb03bE5d3eC3c8fEcE934","0xa2a7b718Af3CD7F18354Ac5E02235ea6C035BD57"]




// contract CalledContract1{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }

// contract CalledContract2{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }


// contract CalledContract3{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }


// contract CalledContract4{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }


// contract CalledContract5{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }


// contract CalledContract6{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }


// contract CalledContract7{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }


// contract CalledContract8{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }


// contract CalledContract9{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }


// contract CalledContract{
// 	uint public x;
// 	uint public value = 123;
// 	function setX(uint _x) external {
// 		x = _x;
// 	}
// }