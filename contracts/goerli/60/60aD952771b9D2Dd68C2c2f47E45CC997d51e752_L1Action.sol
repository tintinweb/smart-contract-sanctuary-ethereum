pragma solidity 0.8.13;


interface ICairoVerifier {
    function isValid(bytes32) external view returns (bool);
}

contract L1Action
{   
    // SHARP - Cairo verifier contract
    //TODO: update to mainnet address
    address constant GOERLY_SHARP_VERIFIER = 0xAB43bA48c9edF4C2C4bB01237348D1D7B28ef168;
    ICairoVerifier public cairoVerifier = ICairoVerifier(GOERLY_SHARP_VERIFIER);


    // Cairo version/hash
    bytes32 public cairoProgramHash=0x0; 

    // Event confirming proper execution
    event ActionExecuted(bytes32 cairoProgramHash, uint256[] cairoProgramOutput);

    // TODO: add Owner as only Admins should be able to change Cairo program hash
    function updateCairoProgramHash(bytes32 _cairoProgramHash) external {
        cairoProgramHash = _cairoProgramHash;
    }

    function execute_action(uint256[] memory cairoProgramOutput) external {

        bytes32 cairoProgramOutputHash = keccak256(abi.encodePacked(cairoProgramOutput));
        bytes32 fact = keccak256(abi.encodePacked(cairoProgramHash, cairoProgramOutputHash));

        // Check with SHARP if execution was done
        require(cairoVerifier.isValid(fact), "Wrong proof");

        // Simulating whatever action
        emit ActionExecuted(cairoProgramHash, cairoProgramOutput);

    }

}