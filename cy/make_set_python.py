def make_set(s):
    xxset = set()
    for i in range(0, len(s), 3):
        xxset.add(s[i:i+3])
    return xxset


def detect_users(nets_bytes_1, nets_bytes_2):
    set1 = make_set(nets_bytes_1)
    set2 = make_set(nets_bytes_2)
    n_same = 0
    for it in set1:
        if it in set2:
            # print(it)
            n_same += 1
            if n_same >= 2:
                return True
    return False

def detect_users2(nets_bytes_1, nets_bytes_2):
    set1 = make_set(nets_bytes_1)
    n_same = 0
    for i in range(0, len(nets_bytes_2), 3):
        if nets_bytes_2[i:i+3] in set1:
            # print(it)
            n_same += 1
            if n_same >= 2:
                return True
    return False
