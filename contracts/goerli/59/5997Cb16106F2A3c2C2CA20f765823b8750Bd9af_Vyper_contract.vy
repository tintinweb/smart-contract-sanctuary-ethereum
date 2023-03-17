resumed_timestamp: uint256


@external
@view
def isPaused() -> bool:
    return self._is_paused()


@external
def pauseFor(_duration: uint256):
    if not self._is_paused():
        self.resumed_timestamp = block.timestamp + _duration

@internal
@view
def _is_paused() -> bool:
    return block.timestamp < self.resumed_timestamp