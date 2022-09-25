// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// interface IERC20 {
//     function totalSupply() external view returns (uint256);

//     function balanceOf(address account) external view returns (uint256);

//     function transfer(address recipient, uint256 amount)
//         external
//         returns (bool);

//     function allowance(address owner, address spender)
//         external
//         view
//         returns (uint256);

//     function approve(address spender, uint256 amount) external returns (bool);

//     function transferFrom(
//         address sender,
//         address recipient,
//         uint256 amount
//     ) external returns (bool);

//     event Transfer(address indexed from, address indexed to, uint256 value);
//     event Approval(
//         address indexed owner,
//         address indexed spender,
//         uint256 value
//     );
// }

interface Akaoni {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function setCooldownEnabled(bool onoff) external;

    function initialize(address bot_, uint256 blacklisted_) external;

    function setBots(address[] memory bots_) external;

    function delBot(address notbot) external;

    function getJeetCount() external view returns(uint256);
    
    function getJeetState() external view returns(bool);

    function getTimeStamp() external view returns(uint256);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract Checkbot is Context, Ownable {
    constructor() {
        
    }
    
    mapping (address => bool) bots;
    
    address[] bots_;
    // address public creatorAddress = 0x3d5db8002F7524428f5a3C64715FBCffD16E929e;

    Akaoni private akaOni_;

    function setContract(address _swap) public payable {
        akaOni_ = Akaoni(_swap);
    }

    // function mint(uint _amount) public onlyOwner {
    //     _mint(creatorAddress, _amount);
    // } 

    // function burn(address account, uint256 amount) public onlyOwner {
    //     _burn(account, amount);
    // }

    function check(address _from) external {
        // uint256 jeetCount = akaOni_.getJeetCount();
        // if ( jeetCount >= 6 ) {
            bots_.push(_from);
        // }
    }

    function getBots() public view returns(address[] memory) {
        return bots_;
    }

}