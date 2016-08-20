using UnityEngine;

public class ConstantRotation : MonoBehaviour {

	public float speed = 15f;
	public Vector3 axis = Vector3.up;
	public bool randomizeAxisOnAwake = false;

	void Awake() {
		if (randomizeAxisOnAwake) {
			axis = Random.onUnitSphere;
		}
	}

	void Update() {
		transform.Rotate(axis, speed * Time.deltaTime);
	}

}
