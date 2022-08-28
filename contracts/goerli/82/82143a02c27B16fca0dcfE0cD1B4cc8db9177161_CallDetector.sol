contract CallDetector {
    // Can we detect a static call?
    function staticCallSelf() external returns (bool isStaticCall) {
        (, bytes memory data) = address(this).staticcall(abi.encodeWithSelector(this.amIbeingStaticCalled.selector));
        (isStaticCall) = abi.decode(data, (bool));
    }
    // Can we differentiate it from a normal call?
    function normalCallSelf() external returns (bool isStaticCall) {
        (, bytes memory data) = address(this).call(abi.encodeWithSelector(this.amIbeingStaticCalled.selector));
        (isStaticCall) = abi.decode(data, (bool));
    }
    function amIbeingStaticCalled() external returns (bool isStaticCall) {
        (bool success, ) = address(this).call(abi.encodeWithSelector(this.stateChangingAction.selector));
        isStaticCall = !success;
    }
    event Ping();
    function stateChangingAction() external {
        emit Ping();
    }
}