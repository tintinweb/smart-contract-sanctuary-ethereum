/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-04-26
*/

pragma solidity >= 0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
contract FPLandNFTURI {
    using Strings for uint;
    using Strings for uint8;
    using Strings for uint256;
	
    address public superManager = 0xaA04E088eBbf63877a58F6B14D1D6F61dF9f3EE8;
    address public manager;

    mapping (uint8 => string) public LandTypeName;
	
    constructor() public{
        manager = msg.sender;
		LandTypeName[0] = "";
		LandTypeName[1] = "Commercial Land";
		LandTypeName[2] = "Residential Land";
		LandTypeName[3] = "Agricultural Land";
		LandTypeName[4] = "Industrial Land";
		LandTypeName[5] = "Mining Land";
		LandTypeName[6] = "Sapphire Specific Sites";
		LandTypeName[7] = "Jadeite Specific Sites";
		LandTypeName[8] = "Amethyst Specific Sites";
    }

    modifier onlyManager{
        require(msg.sender == manager || msg.sender == superManager, "Not manager");
        _;
    }

    function changeManager(address _new_manager) public {
        require(msg.sender == superManager, "It's not superManager");
        manager = _new_manager;
    }

	//----------------Add URI----------------------------
	//--Manager only--//

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
	
	//--Get token URI uint--//
    function GettokenURI(
	uint _NFTID, 
	uint _tokenID
	) public view returns(string memory){
	
        uint8 _LandType = uint8(_tokenID % 8 + 1);
        uint _AreaNO = _tokenID % 25;
        uint _LandNO = _tokenID % 10000;
        uint _CoordinateX = _tokenID % 100;
        uint _CoordinateY = _tokenID % 100;
        uint _ARADailyProfit = _NFTID;

        string memory _PreLink1 = GetPreLink1(_LandType);
        string memory _PreLink2 = GetPreLink2(_AreaNO, _LandNO);
        string memory _PreLink3 = GetPreLink3(_CoordinateX, _CoordinateY);
        string memory _PreLink4 = GetPreLink4(_ARADailyProfit);
        string memory _finalLink1 = strConcat(_PreLink1, _PreLink2);
        string memory _finalLink2 = strConcat(_PreLink3, _PreLink4);

        return strConcat(_finalLink1, _finalLink2);
    }

	//--Get PreLink1 string--//
    function GetPreLink1(uint8 _LandType) public view returns(string memory){
        string memory _LandTypeSTR = uint2str(uint(_LandType));

        return string(
          abi.encodePacked(
            abi.encodePacked(
			  bytes('data:application/json;utf8,{"name": "Freeport Land NFT -'),
              LandTypeName[_LandType],
			  bytes('-","description": "Freeport Metaverse Land NFT.\r\n \r\nFreeport Metaverse is a block-chain game.\r\nWe are trying hard to build an evolable virtual world.\r\n \r\nWebSite:\r\nhttps://freeportmeta.com\r\n \r\nVideo:\r\nhttps://freeportmeta.com/youtube\r\n \r\nLinktree:\r\nhttps://linktr.ee/Freeportgame" , "external_link": "https://freeportmeta.com/FPLandNFT/ipfs/" , "image": "https://freeportmeta.com/FPLandNFT/ipfs/0/'),
              _LandTypeSTR,
			  bytes(' .png"," ')
            ),
            abi.encodePacked(
			  bytes('attributes": [{"trait_type": "Land Type" , "value": "'),
              LandTypeName[_LandType],
			  bytes('"},{"trait_type": "AreaNO","value": "')
            )
          )
        );

    }
	
	//--Get PreLink2 string--//
    function GetPreLink2(uint _AreaNO, uint _LandNO) public view returns(string memory){
        string memory _AreaNOSTR = uint2str(_AreaNO);
        string memory _LandNOSTR = uint2str(_LandNO);

        return string(
          abi.encodePacked(
            abi.encodePacked(
			  bytes('"},{"trait_type": "AreaNO","value": "'),
              _AreaNOSTR
            ),
            abi.encodePacked(
			  bytes('"},{"trait_type": "LandNO","value": "'),
              _LandNOSTR
            )
          )
        );
    }
	
	//--Get PreLink3 string--//
    function GetPreLink3(uint _CoordinateX, uint _CoordinateY) public view returns(string memory){
        string memory _CoordinateXSTR = uint2str(_CoordinateX);
        string memory _CoordinateYSTR = uint2str(_CoordinateY);

        return string(
          abi.encodePacked(
            abi.encodePacked(
			  bytes('"},{"trait_type": "CoordinateX","value": "'),
              _CoordinateXSTR
            ),
            abi.encodePacked(
			  bytes('"},{"trait_type": "CoordinateY","value": "'),
              _CoordinateYSTR
            )
          )
        );
    }
	
	//--Get PreLink4 string--//
    function GetPreLink4(uint _ARADailyProfit) public view returns(string memory){
        string memory _ARADailyProfitSTR = uint2str(_ARADailyProfit);

        return string(
          abi.encodePacked(
            abi.encodePacked(
			  bytes('"},{"trait_type": "ARA Daily Profit","value": "'),
              _ARADailyProfitSTR
            ),
            abi.encodePacked(
			  bytes('"}]}')
            )
          )
        );
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