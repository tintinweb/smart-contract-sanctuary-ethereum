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

    function caller() external {
        address(a).call{gas: 30_000_000 - 21_000}(
            abi.encodeWithSelector(a.abc.selector)
        );
    }
}