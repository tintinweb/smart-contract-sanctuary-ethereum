pragma solidity 0.8.12;
import "./IKingSlayer.sol";
import "./KingSlayer.sol";
/*
* @author Razzor (https://ciphershastra/KingSlayer.html)
*/

contract Deployer{
    mapping(address => address) public imps;
    error InsufficientBalance(uint Restored, uint Provided, uint Remaining);
    address public owner = msg.sender;
    address immutable slayer;

    constructor(address Kingslayer){
        slayer = address(new KingSlayer());
    }

    function deploy() external payable returns(address){
        address implementation = slayer;

        address currentInstance = imps[msg.sender];
        uint balance_restored = 0;

        if(currentInstance != address(0)) {
            address King = IKingSlayer(currentInstance).King();

            if(King == address(this) || King == msg.sender){

                uint old_value = address(this).balance;
                IKingSlayer(currentInstance).destroy();
                uint new_value = address(this).balance;
                balance_restored = new_value-old_value;
            }
        }

        uint total_value = balance_restored + msg.value;

        if (total_value < 0.01 ether){
            revert InsufficientBalance(balance_restored, total_value, 0.01 ether - total_value);
        }
        else{
            payable(msg.sender).transfer(total_value - 0.01 ether);
        }
        address instance;
        /// @solidity memory-safe-assembly
        /// Borrowed from Openzeppelin's Clones Lib (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol) 
        assembly {
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }

        require(instance != address(0), "ERC1167: create failed");

        imps[msg.sender] = instance;

        IKingSlayer(instance).initialize();

        (bool success,)=payable(instance).call{value: 0.01 ether}("");

        require(success, "First Contribution failed");

        return instance;
    }

    function verify(address currentInstance) external payable{
        IKingSlayer slayer  = IKingSlayer(currentInstance);
        require(currentInstance != address(0), "No instance found");
        require(address(this) != slayer.King(), "Challenge Unsolved");
        uint KingsContribution = slayer.KingsContribution();
        slayer.gameOfThrone{value: KingsContribution + 0.05 ether}();
    }

    function onERC721Received(address a, address b, uint c, bytes memory d) external returns(bytes4){
        return 0x150b7a02;
    }


    function extractFunds(address payable to) external {
        require(msg.sender == owner, "Only Owner");
        to.transfer(address(this).balance);
    }

    fallback() external payable{
        
    }

}