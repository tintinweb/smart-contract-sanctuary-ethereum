/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity =0.8.0;

interface IBarker {
    function author() external view returns (address);
    function replyingTo() external view returns (address);
    function content() external view returns (string memory);
    function claimableTips() external view returns (uint256);
    function claimTips() external;
    event Bark(address author, address replyingTo, string content, uint256 tips);
    event Claimed(address author, address claimer, uint256 amount);
    event TipReceived(address thisBark, address tipper, uint256 amount);
}

contract Barker is IBarker {
    address payable private _author;
    address payable private _replyingTo;
    string private _content;
    
    constructor(address payable replyingTo_, string memory content_) payable {
        _author = payable(msg.sender);
        _replyingTo = replyingTo_;
        _content = content_;
        
        // Send tip when replying (optional).
        _replyingTo.transfer(msg.value);

        emit Bark(_author, _replyingTo, _content, msg.value);
    }

    function author() public view override returns (address) {
        return _author;
    }
    
    function replyingTo() public view override returns (address) {
        return _replyingTo;
    }

    function content() public view override returns (string memory) {
        return _content;
    }

    function claimableTips() public view override returns (uint256) {
        return address(this).balance;
    }
    
    function claimTips() public override {
        uint256 _amount = address(this).balance;
        _author.transfer(_amount);
        
        // Other people can claim for the author.
        emit Claimed(_author, msg.sender, _amount);
    }
    
    receive() external payable {
        emit TipReceived(address(this), msg.sender, msg.value);
    }
}