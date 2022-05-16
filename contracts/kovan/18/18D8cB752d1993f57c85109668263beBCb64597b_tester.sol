contract tester {
    event Emited(uint256 a);

    constructor(){}

    function emitEvent() external {
        emit Emited(0);
    }
}