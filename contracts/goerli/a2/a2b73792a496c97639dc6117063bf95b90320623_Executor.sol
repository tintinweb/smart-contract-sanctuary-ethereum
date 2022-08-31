pragma solidity 0.8.10;

contract Abs {
    function abc() external {
        while (true) {
            assert(true);
        }
    }
}

contract Executor {
    Abs a;

    constructor() {
        a = new Abs();
    }

    function caller() external payable {
        block.coinbase.transfer(msg.value);
        address(a).call{gas: gasleft()}(
            abi.encodeWithSelector(a.abc.selector)
        );
    }
}