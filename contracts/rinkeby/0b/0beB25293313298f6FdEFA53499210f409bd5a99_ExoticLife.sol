// SPDX-License-Identifier: MIT

// Into the Metaverse NFTs are governed by the following terms and conditions: https://a.did.as/into_the_metaverse_tc

pragma solidity ^0.8.9;

import "./counters.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./strings.sol";
import "./AbstractERC1155Factory.sol";


/*
* @title ERC1155 ExoticLife
* @author Exotic Technology
*/
contract ExoticLife is AbstractERC1155Factory {

    uint256 constant MAX_SUPPLY = 5000;
    
    uint256 constant MAX_COPPER = 3000;
    uint256 constant MAX_BRONZE = 1000;
    uint256 constant MAX_SILVER = 500;
    uint256 constant MAX_GOLD = 300;
    uint256 constant MAX_PLATINUM = 200;

    

    /*
    uint8 maxPerTx = 2;
    uint8 maxTxPublic = 2;
    uint8 maxTxEarly = 1;

    uint256 public mintPrice = 200000000000000000;
    uint256 public cardIdToMint = 1;
 
    uint256 public earlyAccessWindowOpens = 32533921476;
    uint256 public purchaseWindowOpens    = 32533921477;
    uint256 public purchaseWindowCloses   = 32533921478;

    uint256 public burnWindowOpens  = 32533921479;
    uint256 public burnWindowCloses = 32533921480;
  
    bytes32 public merkleRoot;
     */
    mapping(address => uint256) public purchaseTxs;

    event RedeemedForCard(uint256 indexed indexToRedeem, uint256 indexed indexToMint, address indexed account, uint256 amount);
    event Purchased(uint256 indexed index, address indexed account, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }


    function maxPerToken(uint256 _id)internal pure returns (uint256 num){
        require(_id <= 4, "token out of bounds");

        if(_id == 0){
            return MAX_COPPER;
        }
        else if(_id == 1){
            return MAX_BRONZE;
        }

        else if(_id == 2){
            return MAX_SILVER;
        }

        else if(_id == 3){
            return MAX_GOLD;
        }

        else if(_id == 4){
            return MAX_PLATINUM;
        }

    }

    function purchase(uint256 amount) external payable {
        uint256 randNum = block.timestamp % 5;
        require(amount > 0);
        require(totalSupply(randNum) + amount <= maxPerToken(randNum));

        _purchase(randNum, amount);

    }

    /**
    * @notice global purchase function used in early access and public sale
    *
    * @param amount the amount of tokens to purchase
    */
    function _purchase(uint256 id, uint256 amount) private {
    
        purchaseTxs[msg.sender] += 1;

        _mint(msg.sender, id, amount, "");
        emit Purchased(0, msg.sender, amount);
    }


    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");

            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }
}