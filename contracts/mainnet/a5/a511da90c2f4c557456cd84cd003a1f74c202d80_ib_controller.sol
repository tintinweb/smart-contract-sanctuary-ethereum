/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ib {
    function acceptGov() external;
    function balanceOf(address) external view returns (uint);
    function burn(uint amount) external;
    function deposit() external;
    function mint(uint amount) external;
    function profit() external;
    function setGov(address gov) external;
    function transfer(address dst, uint amount) external returns (bool);
    function withdraw(uint amount) external;
}

contract ib_controller {

    address public burner; // contract to normalize profit into ibEUR and distribute to ve_dist
    address public msig;
    address public next_msig;
    uint public commit_msig;
    uint public constant delay = 1 days;

    address[] public tokens; // list of tokens (simplifies profit calls)

    modifier is_msig() {
        require(msg.sender == msig);
        _;
    }

    constructor(address _msig, address _burner) {
        msig = _msig;
        burner = _burner;
    }

    // set the burner contract that normalizes tokens
    function set_burner(address _burner) is_msig external {
        burner = _burner;
    }

    // set the new msig with 1 day delay
    function set_msig(address _msig) is_msig external {
        next_msig = _msig;
        commit_msig = block.timestamp + delay;
    }

    // accept msig for the new controller
    function accept_msig() external {
        require(msg.sender == next_msig && commit_msig < block.timestamp);
        msig = next_msig;
    }

    // used to accept gov on underlying ib tokens for this contract
    function accept_gov(address token) is_msig external {
        ib(token).acceptGov();
        tokens.push(token);
    }

    // set the governance for a token to a new governance
    function set_gov(address token, address nextgov) is_msig external {
        ib(token).setGov(nextgov);
    }

    // mint new ib tokens and deposit into the Iron Bank
    function mint_and_deposit(address token, uint amount) is_msig external {
        ib(token).mint(amount);
        ib(token).deposit();
    }

    // withdraw ib tokens from Iron Bank and burn
    function withdraw_and_burn(address token, uint amount) is_msig external {
        ib(token).withdraw(amount);
    }

    // claim profits and distribute to ve_dist
    function profit() external {
        profit(tokens);
    }

    // fallback incase tokens are changed to a new governance
    function profit(address[] memory _tokens) public {
        for (uint i = 0; i < _tokens.length; i++) {
            ib _token = ib(_tokens[i]);
            _token.profit();
            _token.transfer(burner, _token.balanceOf(address(this)));
        }
    }

}