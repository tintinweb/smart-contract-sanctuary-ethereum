/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

pragma solidity >= 0.5.17;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract InitializeIASC {
    using SafeMath for uint256;
    using SafeMath for uint;
	
    mapping(uint256 => string) private _NFTHash;
    mapping(uint256 => string) private _Trait;
	
    constructor() public{
		_NFTHash[0] = "6b51d431df5d7f141cbececcf79edf3dd861c3b4069f0b11661a3eefacbba918";
		_NFTHash[1] = "03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4";
		_NFTHash[2] = "8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92";
		_NFTHash[3] = "ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f";
		_NFTHash[4] = "63640264849a87c90356129d99ea165e37aa5fabc1fea46906df1a7ca50db492";
		_NFTHash[5] = "21aa9e5a7b7bcb8ce51ab1f3a2ba2f74059909d03f15a44e32caadc3bbed930e";
		_NFTHash[6] = "42a964b33db20832714a145d06a83cac8c9143595dd067ba9603d7cb561d4e20";
		_NFTHash[7] = "fe8c1bc23216bd64b5bda4088b600642fe11718dca88e9dbd776da59d2c5c7df";
		_NFTHash[8] = "d2dd9e95852df53904aec96278d0174f617ad919eb36981aae2b912bf3812922";
		_NFTHash[9] = "ac0f6c5ad9f795ea5b958fedb929eec2201bbb7af8b65d393d7efe51275ae254";
		
		_Trait[0] = "Front View";
		_Trait[1] = "Ear";
		_Trait[2] = "Head";
		_Trait[3] = "Eye";
		_Trait[4] = "Mouth";
		_Trait[5] = "Clothing";
		_Trait[6] = "Fur Color";
		_Trait[7] = "Accessories";
		_Trait[8] = "Background";
    }

    function GettokenURI(
	uint256 _TokenID,
	uint256 _IASCEquity,
	uint256 _Refund
	) public view returns(string memory){
	
		uint256[] memory TraitData = new uint256[](9);
		TraitData = InitTraitData(_TokenID);
	
        string memory _PreLink1 = GetPreLink1(_TokenID, _IASCEquity, _Refund);
        string memory _PreLink2 = GetPreLink2(TraitData[0], TraitData[1], TraitData[2]);
        string memory _PreLink3 = GetPreLink3(TraitData[3], TraitData[4], TraitData[5]);
        string memory _PreLink4 = GetPreLink4(TraitData[6], TraitData[7], TraitData[8]);

        string memory _finalLink1 = strConcat(_PreLink1, _PreLink2);
        string memory _finalLink2 = strConcat(_PreLink3, _PreLink4);

        return strConcat(_finalLink1, _finalLink2);
    }

    function GetPreLink1(uint _TokenID, uint _IASCEquity, uint _Refund) public view returns(string memory){
        string memory _TokenIDSTR = uint2str(_TokenID);
        string memory _IASCEquitySTR = uint2str(_IASCEquity);
        string memory _RefundSTR = uint2str(_Refund);

        return string(
          abi.encodePacked(
            abi.encodePacked(
			  bytes('data:application/json;utf8,{"name": "Infinite Ape Spaceship Club NFT -#'),
              _TokenIDSTR,
			  bytes('- ","description": "description": "Infinite Ape Spaceship Club description." , "external_link": "https://infiniteape.club/ipfs/" , "image": "https://infiniteape.club/ipfs/'),
              _TokenIDSTR,
			  bytes(' .png"," ')
            ),
            abi.encodePacked(
			  bytes('attributes": [{"trait_type": "IASC Equity" , "value": "'),
              _IASCEquitySTR,
			  bytes('"},{"trait_type": "Refund Amounts" , "value": "'),
              _RefundSTR,
			  bytes(' ')
            )
          )
        );
    }

    function GetPreLink2(uint _FrontView, uint _Ear, uint _Head) public view returns(string memory){
        string memory _FrontViewSTR = uint2str(_FrontView);
        string memory _EarSTR = uint2str(_Ear);
        string memory _HeadSTR = uint2str(_Head);
		
        return string(
          abi.encodePacked(
            abi.encodePacked(
			  bytes('"},{"trait_type": "'),
              _Trait[0],
			  bytes('"},{"","value": "'),
			  _FrontViewSTR,
			  bytes('"},{"trait_type": "'),
              _Trait[1],
			  bytes('"},{"","value": "'),
			  _EarSTR,
			  bytes(' ')
            ),
            abi.encodePacked(
			  bytes('"},{"trait_type": "'),
              _Trait[2],
			  bytes('"},{"","value": "'),
			  _HeadSTR,
			  bytes(' ')
            )
          )
        );
    }

    function GetPreLink3(uint _Eye, uint _Mouth, uint _Clothing) public view returns(string memory){
        string memory _EyeSTR = uint2str(_Eye);
        string memory _MouthSTR = uint2str(_Mouth);
        string memory _ClothingSTR = uint2str(_Clothing);
		
        return string(
          abi.encodePacked(
            abi.encodePacked(
			  bytes('"},{"trait_type": "'),
              _Trait[3],
			  bytes('"},{"","value": "'),
			  _EyeSTR,
			  bytes('"},{"trait_type": "'),
              _Trait[4],
			  bytes('"},{"","value": "'),
			  _MouthSTR,
			  bytes(' ')
            ),
            abi.encodePacked(
			  bytes('"},{"trait_type": "'),
              _Trait[5],
			  bytes('"},{"","value": "'),
			  _ClothingSTR,
			  bytes(' ')
            )
          )
        );
    }

    function GetPreLink4(uint _FurColor, uint _Accessories, uint _Background) public view returns(string memory){
        string memory _FurColorSTR = uint2str(_FurColor);
        string memory _AccessoriesSTR = uint2str(_Accessories);
        string memory _BackgroundSTR = uint2str(_Background);

        return string(
          abi.encodePacked(
            abi.encodePacked(
			  bytes('"},{"trait_type": "'),
              _Trait[6],
			  bytes('"},{"","value": "'),
			  _FurColorSTR,
			  bytes('"},{"trait_type": "'),
              _Trait[7],
			  bytes('"},{"","value": "'),
			  _AccessoriesSTR,
			  bytes(' ')
            ),
            abi.encodePacked(
			  bytes('"},{"trait_type": "'),
              _Trait[8],
			  bytes('"},{"","value": "'),
			  _BackgroundSTR,
			  bytes('"}]}')
            )
          )
        );
    }

    function InitTraitData(uint256 _TokenID) public view returns(uint256[] memory){
		bytes memory seed0 = abi.encodePacked(_TokenID, _NFTHash[(_TokenID + 1) % 10]);
		bytes memory seed1 = abi.encodePacked(_TokenID+5, _NFTHash[(_TokenID + 2) % 10]);
		bytes memory seed2 = abi.encodePacked(_TokenID+7, _NFTHash[(_TokenID + 3) % 10]);
		bytes memory seed3 = abi.encodePacked(_TokenID+11, _NFTHash[(_TokenID + 4) % 10]);
		bytes memory seed4 = abi.encodePacked(_TokenID+13, _NFTHash[(_TokenID + 5) % 10]);
		bytes memory seed5 = abi.encodePacked(_TokenID+17, _NFTHash[(_TokenID + 6) % 10]);
		bytes memory seed6 = abi.encodePacked(_TokenID+19, _NFTHash[(_TokenID + 7) % 10]);
		bytes memory seed7 = abi.encodePacked(_TokenID+23, _NFTHash[(_TokenID + 8) % 10]);
		bytes memory seed8 = abi.encodePacked(_TokenID+29, _NFTHash[(_TokenID + 9) % 10]);

		uint256[] memory TraitData = new uint256[](9);
		TraitData[0] = rand(seed0, 1, 8);
		TraitData[1] = rand(seed1, 1, 13);
		TraitData[2] = rand(seed2, 1, 13);
		TraitData[3] = rand(seed3, 1, 13);
		TraitData[4] = rand(seed4, 1, 7);
		TraitData[5] = rand(seed5, 1, 7);
		TraitData[6] = rand(seed6, 1, 7);
		TraitData[7] = rand(seed7, 1, 13);
		TraitData[8] = rand(seed8, 1, 7);

		return TraitData;
    }
	
    function rand(bytes memory seed, uint bottom, uint top) internal pure returns(uint){
		require(top >= bottom, "bottom > top");
		if(top == bottom){
		  return top;
		}
		uint _range = top.sub(bottom);

		uint n = uint(keccak256(seed));
		return n.mod(_range).add(bottom).add(1);
    }
	
	
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
	
	function strConcat(string memory _a, string memory _b) internal view returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;

        for (uint i = 0; i < _ba.length; i++){
            bret[k++] = _ba[i];
        }
        for (uint i = 0; i < _bb.length; i++){
            bret[k++] = _bb[i];
        }
        return string(ret);
	} 
}