/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;


contract Controlled {
    address public Controller;

    /**
      * The Controlled constructor sets the original `Controller` of the contract to the sender
      * account.
      */
    constructor() public {
        Controller = msg.sender;
    }

    /**
      * Throws if called by any account other than the Controller.
      */
    modifier OnlyController() {
        require(msg.sender == Controller);
        _;
    }

    /**
    * Allows the current controller to transfer control of the contract to a NewController.
    * NewController: The address to transfer ownership to.
    */
    function TransferControl(address NewController) public OnlyController {
        if (NewController != address(0)) {
            Controller = NewController;
        }
    }

}

 /**
    * Main contract VesselIdentifierVariables includes general Identifiers of the veseel such as Gross Tonnage,
    * Length Overall, Net Tonnage, Type of Vessel, Vessel Name and Owner.
    * Editing data requires Owner level access, which is coming fom Ownable.
    */

contract VesselIdentifierVariables is Controlled {

    string public GrossTonnage = "GrossTonnage not set yet";
    
    function ChangeGrossTonnage(string memory _GrossTonnage) OnlyController public {
        GrossTonnage = _GrossTonnage;
    }
    

    string public LengthOverall = "LengthOverall is not set yet";
    
    function ChangeLengthOverall(string memory _LengthOverall) OnlyController public {
        LengthOverall = _LengthOverall;
    }

    
      string public NetTonnage = "NetTonnage is not set yet";
    
    function ChangeNetTonnage(string memory _NetTonnage) OnlyController public {
        NetTonnage = _NetTonnage;
    }  
    
        string public TypeOfVessel = "TypeOfVessel is not set yet";
    
    function ChangeTypeOfVessel(string memory _TypeOfVessel) OnlyController public {
        TypeOfVessel = _TypeOfVessel;
    }

        string public VesselName = "VesselName is not set yet";
    
    function ChangeVesselName(string memory _VesselName) OnlyController public {
        VesselName = _VesselName;
    }

        string public VesselOwner = "VesselOwner is not set yet";
    
    function ChangeVesselOwner(string memory _VesselOwner) OnlyController public {
        VesselOwner = _VesselOwner;
    }
    

    address public VesselClassificationContract = 0x0000000000000000000000000000000000000000;
    
    function ChangeVesselClassificationContract(address _VesselClassificationContract) OnlyController public {
    VesselClassificationContract = _VesselClassificationContract;
    }


        address public VesselCertificatesContract = 0x0000000000000000000000000000000000000000;
    
    function ChangeVesselCertificatesContract(address _VesselCertificatesContract) OnlyController public {
    VesselCertificatesContract = _VesselCertificatesContract;
    }


        address public ShippingCompanyContract = 0x0000000000000000000000000000000000000000;
    
    function ChangeShippingCompanyContract(address _ShippingCompanyContract) OnlyController public {
    ShippingCompanyContract = _ShippingCompanyContract;
    }


    // below section makes it possible to call information from another smart contract.

    function GrossTonnageRemote() external view returns (string memory) {
        return GrossTonnage;
    }

    function LengthOverallRemote() external view returns (string memory) {
        return LengthOverall;
    }

    function NetTonnageRemote() external view returns (string memory) {
        return NetTonnage;
    }    
    
    function TypeOfVesselRemote() external view returns (string memory) {
        return TypeOfVessel;
    }

    function VesselNameRemote() external view returns (string memory) {
        return VesselName;
    }

    function VesselOwnerRemote() external view returns (string memory) {
        return VesselOwner;
    }
   
}