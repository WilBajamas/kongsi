/// Whether the device currently has a network. This is *connectivity*, not
/// reachability: online means "there is a network to try", never a guarantee
/// the server can be reached.
enum ConnectivityStatus { online, offline }
