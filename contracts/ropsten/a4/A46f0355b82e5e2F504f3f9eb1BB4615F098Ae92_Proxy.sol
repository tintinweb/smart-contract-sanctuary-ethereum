contract Proxy {
    address delegate;

    /*constructor(bytes32 hash, uint8 v, bytes32 r, bytes32 s) {
        delegate = ecrecover(hash, v, r, s);
    }*/
    
    constructor(address target) {
        delegate = target;
    }

    fallback() external payable {
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}