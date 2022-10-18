import "./BaseRelayRecipient.sol";

// solhint-disable no-inline-assembly
pragma solidity ^0.6.2;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Disperse is BaseRelayRecipient {
    constructor(address _trustedForwarder) public {
        trustedForwarder = _trustedForwarder;
    }


    function disperseEther(address[] calldata recipients, uint256[] calldata values) external payable {
        for (uint256 i = 0; i < recipients.length; i++) {
            address payable recipient = payable(recipients[i]);
            recipient.transfer(values[i]);
        }
            
        uint256 balance = address(this).balance;
        if (balance > 0)
            _msgSender().transfer(balance);
    }

    function disperseToken(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(_msgSender(), address(this), total));
        for (uint i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function disperseTokenSimple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(_msgSender(), recipients[i], values[i]));
    }

    function versionRecipient() external view override returns (string memory) {
        return "1";
    }
}