# @version ^0.3.7

@external
def is_valid_ERC1271_signature_now(signer: address) ->  Bytes[32]:
    return_data: Bytes[32] = b""
    return_data = raw_call(signer, method_id("isValidSignature()"), max_outsize=32)
    return return_data