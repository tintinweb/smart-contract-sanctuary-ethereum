/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity =0.8.16;

// Developed by Orcania (https://orcania.io/)
interface IERC20 {
         
    function transfer(address recipient, uint256 amount) external;
    
}

interface IERC721 {

    function balanceOf(address _owner) external view returns (uint256);

}

abstract contract OMS { //Orcania Management Standard

    address private _owner;

    event OwnershipTransfer(address indexed newOwner);

    receive() external payable {}

    constructor() {
        _owner = msg.sender;
    }

    //Modifiers ==========================================================================================================================================
    modifier Owner() {
        require(msg.sender == _owner, "OMS: NOT_OWNER");
        _;  
    }


    //Read functions =====================================================================================================================================
    function owner() public view returns (address) {
        return _owner;
    }
    
    //Write functions ====================================================================================================================================
    function setNewOwner(address user) external Owner {
        _owner = user;
        emit OwnershipTransfer(user);
    }
    
    function withdraw(address payable to, uint256 value) external Owner {
        sendValue(to, value);  
    }

    function withdrawERC20(address token, address to, uint256 value) external Owner {
        IERC20(token).transfer(to, value);   
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "UNABLE_TO_SEND_VALUE RECIPIENT_MAY_HAVE_REVERTED");
    }

}

contract OCAmint is OMS {
    IERC20 immutable OCA;

    mapping (address => bool) private _partnered;//If the following ERC721 contract address is partnered with Orcania
    mapping (address => bool) private _whiteListed;//If the following user address is white listed

    uint256 private _price;
    uint256 private _partnerPrice;
    uint256 private _whiteListPrice;

    constructor(address oca) {
        OCA = IERC20(oca);
    }

    //Read functions=========================================================================================================================
    function price() external view returns (uint256) {return _price;}

    function partnerPrice() external view returns (uint256) {return _partnerPrice;}
    
    function whiteListPrice() external view returns (uint256) {return _whiteListPrice;}

    function whiteListed(address user) external view returns(bool) {return _whiteListed[user];} 

    //Fillings=====================================================================================================================================
    function getFillerVariable() external view returns(uint256) {return 5;}

    //Owner Write Functions========================================================================================================================
    function changePrice(uint256 price, uint256 partnerPrice, uint256 whiteListPrice) external Owner {
        _price = price;
        _partnerPrice = partnerPrice;
        _whiteListPrice = whiteListPrice;    
    }  

    function setPartner(address partner, bool partnered) external Owner {
        _partnered[partner] = partnered;
    }

    function setWhiteList(address user, bool whiteListed) external Owner {
        _whiteListed[user] = whiteListed;
    }

    //User write functions=========================================================================================================================
    function mint() external payable {
        uint256 price = _price;

        require(msg.value % price == 0);
        uint256 amount = msg.value / price * 10**18;

        OCA.transfer(msg.sender, amount);
    }

    function partnerMint(address partnerContract) external payable {
        require(_partnered[partnerContract], "NOT_A_PARTNER");
        require(IERC721(partnerContract).balanceOf(msg.sender) > 0, "NOT_A_PARTNER_HOLDER");

        uint256 price = _partnerPrice;

        require(msg.value % price == 0);
        uint256 amount = msg.value / price * 10**18;

        OCA.transfer(msg.sender, amount);
    }

    function whiteListMint() external payable {
        require(_whiteListed[msg.sender], "NOT_WHITE_LISTED");

        uint256 price = _whiteListPrice;

        require(msg.value % price == 0);
        uint256 amount = msg.value / price * 10**18;

        OCA.transfer(msg.sender, amount);
    }

}