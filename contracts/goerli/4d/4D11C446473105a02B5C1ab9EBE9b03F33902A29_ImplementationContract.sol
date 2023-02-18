contract ImplementationContract {
    bool public isInitialized;

    //initializer function that will be called once, during deployment.
    function initializer() external {
        require(!isInitialized);
        isInitialized = true;
    }
}