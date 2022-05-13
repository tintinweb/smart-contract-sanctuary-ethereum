// Test contract
contract Test {
    // Let's be nice and clean up after ourselves
    function die() {
        suicide(0);
    }
}