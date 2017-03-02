def bytes2set(s, set_type='bytes'):
    if set_type == 'bytes':
        return {s[i:i+3] for i in range(0, len(s), 3)}
    elif set_type == 'int':
        return {int.from_bytes(s[i:i + 3], 'big')
                for i in range(0, len(s), 3)}
    else:
        raise ValueError('Unknown set_type: {}'.format(set_type))


def detect_users(nets_bytes_1, nets_bytes_2):
    set1 = bytes2set(nets_bytes_1)
    n_same = 0
    for i in range(0, len(nets_bytes_2), 3):
        if nets_bytes_2[i:i+3] in set1:
            n_same += 1
            if n_same >= 2:
                return True
    return False
