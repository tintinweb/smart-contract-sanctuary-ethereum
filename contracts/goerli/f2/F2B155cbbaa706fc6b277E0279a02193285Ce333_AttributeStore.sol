pragma solidity^0.4.11;

library AttributeStore {
    struct Data {
        mapping(bytes32 => uint) store;
    }

    //@dev retrieves the voter's attributes set in the setAttribute call
    function getAttribute(Data storage self, bytes32 _UUID, string _attrName)
    public view returns (uint) {
        bytes32 key = keccak256(_UUID, _attrName);
        return self.store[key];
    }

    //@dev stores a hash of the voter address and poll (in which they are participating) together with either
    //     the voter's secret hash (_attrName = "commitHash") or the number of vote credits they wagered (_attrName = "numTokens")
    function setAttribute(Data storage self, bytes32 _UUID, string _attrName, uint _attrVal)
    public {
        bytes32 key = keccak256(_UUID, _attrName);
        self.store[key] = _attrVal;
    }
}