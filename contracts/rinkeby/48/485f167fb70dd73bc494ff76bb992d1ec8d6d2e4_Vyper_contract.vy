# @version ^0.3.1
"""
@title ISCC-HUB Contract v1.0
@notice For use by ISCC-REGISTRAR contracts to announce ISCC-CODES for unique ISCC-ID minting.
@dev For further documentation see https://github.com/iscc/iscc-evm
"""

event IsccDeclaration:
    iscc: String[96]
    url: String[128]
    data: Bytes[128]
    declarer: address
    registrar: address

@external
@payable
def __default__():
    pass

@external
@payable
def iscc_announce(_iscc: String[96], _url: String[128] = "", _data: Bytes[128] = b"") -> bool:
    """
    @notice Emits an event that is interpreted by an ISCC observer to mint/update/delete an ISCC-ID
    @param _iscc ISCC-CODE to be declared (excluding the "ISCC:" prefix)
    @param _url Optional URL of declaration metadata (see: https://schema.iscc.codes)
    @param _data Optional additional declaration data (see: https://github.com/iscc/iscc-evm)
    @dev
        tx.origin = DECLARER - The the address of the declarer (signer of the declaring transaction)
        msg.sender = REGISTRAR - The address of the registrar contract announcing the decleration
    """
    assert tx.origin != msg.sender, "Cannot announce directly, use an ISCC-REGISTRAR contract!"
    log IsccDeclaration(_iscc, _url, _data, tx.origin, msg.sender)
    return True