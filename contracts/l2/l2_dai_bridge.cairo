%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.cairo.common.cairo_builtins import (HashBuiltin, BitwiseBuiltin)
from starkware.cairo.common.math import assert_le
from starkware.starknet.common.syscalls import get_caller_address
from contracts.l2.uint import (uint256, add, sub)

const MESSAGE_WITHDRAW = 0

@contract_interface
namespace IDAI:
    func mint(to_address : felt, value : uint256):
    end

    func burn(from_address : felt, value : uint256):
    end
end

@storage_var
func dai() -> (res : felt):
end

@storage_var
func bridge() -> (res : felt):
end

@storage_var
func initialized() -> (res : felt):
end

@storage_var
func wards(user : felt) -> (res : felt):
end

func auth{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }() -> ():
  let (caller) = get_caller_address()

  let (ward) = wards.read(caller)
  assert ward = 1

  return ()
end

@external
func rely{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(user : felt) -> ():
  auth()
  wards.write(user, 1)
  return ()
end

@external
func deny{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(user : felt) -> ():
  auth()
  wards.write(user, 0)
  return ()
end

@external
func initialize{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(_dai : felt, _bridge : felt):
    let (_initialized) = initialized.read()
    assert _initialized = 0
    initialized.write(1)

    let (caller) = get_caller_address()
    wards.write(caller, 1)

    let (dai_address) = dai.read()
    let (bridge_address) = bridge.read()
    dai.write(_dai)
    bridge.write(_bridge)

    return ()
end

@external
func withdraw{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(l1_address : felt, amount : uint256):
    alloc_locals

    let (dai_address) = dai.read()
    let (caller) = get_caller_address()

    IDAI.burn(contract_address=dai_address, from_address=caller, value=amount)

    let (payload : felt*) = alloc()
    assert payload[0] = MESSAGE_WITHDRAW
    assert payload[1] = l1_address
    assert payload[2] = amount.low
    assert payload[3] = amount.high
    let (bridge_address) = bridge.read()

    send_message_to_l1(to_address=bridge_address, payload_size=4, payload=payload)
    return ()
end

# external is temporary
@external
@l1_handler
func finalizeDeposit{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(from_address : felt, l2_address : felt, amount : uint256):

    # check message was sent by L1 contract
    let (bridge_address) = bridge.read()
    assert from_address = bridge_address

    let (dai_address) = dai.read()
    IDAI.mint(contract_address=dai_address, to_address=l2_address, value=amount)

    return ()
end
