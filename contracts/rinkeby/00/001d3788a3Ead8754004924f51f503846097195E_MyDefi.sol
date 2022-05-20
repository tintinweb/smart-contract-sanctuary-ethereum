pragma solidity ^0.8.0;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract MyDefi{
    event swap_made(address sender, address token, uint userId);
    uint public refereeCommision = 3;
    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function useSwapExactETHForTokens(
        address _uniswap,
        uint _slippage,
        address token,
        uint deadline,
        uint userId
    ) external payable {
        address[] memory path = new address[](2);
        IUniswap uniswap = IUniswap(_uniswap);
        path[0] = uniswap.WETH();
        path[1] = token;

        uint commision = msg.value * refereeCommision;
        uint totalCommision = commision / 100;

        bool success;
        (success,) = address(owner).call{value: totalCommision}("");

        uint totalToBuy = msg.value - totalCommision;

        uint slipagge = totalToBuy * _slippage;
        uint amountOutMin = slipagge / 100;

        uniswap.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            msg.sender,
            deadline
        );

        emit swap_made(msg.sender, token, userId);
    }

    // Set commission
    function setCommision(uint _newCommision) public returns (uint) {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );

        refereeCommision = _newCommision;

        return refereeCommision;
    }
  
}