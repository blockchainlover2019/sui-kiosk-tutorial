module kiosk_test::test {
    use sui::kiosk::{Self, Kiosk};
    use sui::transfer;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    use sui::package;
    use sui::transfer_policy::{Self as policy, TransferPolicy, TransferPolicyCap};

    struct MyNFT has key, store {
      id: UID,
    }

    struct State<phantom T> has key {
      id: UID,
      policy: TransferPolicy<T>,
      policy_cap: TransferPolicyCap<T>
    }

    struct TEST has drop {}

    fun init(witness: TEST, ctx: &mut TxContext) {
      let signer_addr = tx_context::sender(ctx);

      let (kiosk, kiosk_cap) = kiosk::new(ctx);
      let asset = MyNFT {
        id: object::new(ctx)
      };
      let item_id = object::id(&asset);

      let (policy, policy_cap) = get_policy(witness, ctx);
      kiosk::lock(&mut kiosk, &kiosk_cap, &policy, asset);

      kiosk::list<MyNFT>(&mut kiosk, &kiosk_cap, item_id, 0);

      let kiosk_receiver = @0x02f397ba3bbfabba09559c62e3ab88a8d4723d9526406e5c09416e06125ca84a;

      transfer::public_transfer(kiosk, kiosk_receiver);
      transfer::public_transfer(kiosk_cap, kiosk_receiver);

      transfer::transfer(State<MyNFT> {
        id: object::new(ctx),
        policy,
        policy_cap
      }, signer_addr);
    }

    public fun get_policy(witness: TEST, ctx: &mut TxContext): (TransferPolicy<MyNFT>, TransferPolicyCap<MyNFT>) {
        let publisher = package::claim(witness, ctx);
        let (policy, cap) = policy::new(&publisher, ctx);
        package::burn_publisher(publisher);
        (policy, cap)
    }

    entry fun purchase_kiosk(target_kiosk: Kiosk, ctx: &mut TxContext) {
      let signer_addr = tx_context::sender(ctx);
      let new_owner = @0xf548263857565fae205032d49368655167bce62b7cce4ecc3387386b2f176217;
      transfer::public_transfer(target_kiosk, new_owner);
    }
}