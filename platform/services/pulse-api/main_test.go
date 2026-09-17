package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestReadyz(t *testing.T) {
	app := newApp()

	// 1. Al inicio app.ready es false -> debe responder 503 Service Unavailable
	req := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	rec := httptest.NewRecorder()

	app.routes().ServeHTTP(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("esperaba 503 cuando no está listo, obtuve: %d", rec.Code)
	}

	// 2. Simulamos que el inicio completó (ready = true) -> debe responder 200 OK
	app.readyMu.Lock()
	app.ready = true
	app.readyMu.Unlock()

	req = httptest.NewRequest(http.MethodGet, "/readyz", nil)
	rec = httptest.NewRecorder()

	app.routes().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("esperaba 200 cuando está listo, obtuve: %d", rec.Code)
	}
}

func TestCreateCheck(t *testing.T) {
	app := newApp()

	// 1. Caso feliz: enviar URL e intervalo válido
	payload := `{"url": "https://example.com", "interval_seconds": 60}`
	req := httptest.NewRequest(http.MethodPost, "/api/checks", bytes.NewBufferString(payload))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	app.routes().ServeHTTP(rec, req)

	// Validamos que el código HTTP sea 201 Created
	if rec.Code != http.StatusCreated {
		t.Fatalf("esperaba 201 Created, obtuve: %d (body: %s)", rec.Code, rec.Body.String())
	}

	// Decodificamos la respuesta para revisar los datos
	var created Check
	if err := json.NewDecoder(rec.Body).Decode(&created); err != nil {
		t.Fatalf("no se pudo decodificar la respuesta JSON: %v", err)
	}

	if created.ID == "" {
		t.Fatal("esperaba que la API generara un ID para el check, pero vino vacío")
	}

	if created.IntervalS != 60 {
		t.Fatalf("esperaba interval_seconds=60, obtuve: %d", created.IntervalS)
	}

	// 2. Caso de validación: URL vacía -> debe dar 400 Bad Request
	badPayload := `{"url": "", "interval_seconds": 10}`
	req = httptest.NewRequest(http.MethodPost, "/api/checks", bytes.NewBufferString(badPayload))
	req.Header.Set("Content-Type", "application/json")
	rec = httptest.NewRecorder()

	app.routes().ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("esperaba 400 Bad Request para URL vacía, obtuve: %d", rec.Code)
	}

	// 3. Caso valor por defecto: sin interval_seconds -> debe asignar 30s
	defaultPayload := `{"url": "https://google.com"}`
	req = httptest.NewRequest(http.MethodPost, "/api/checks", bytes.NewBufferString(defaultPayload))
	req.Header.Set("Content-Type", "application/json")
	rec = httptest.NewRecorder()

	app.routes().ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("esperaba 201 Created, obtuve: %d", rec.Code)
	}

	var defaultCheck Check
	if err := json.NewDecoder(rec.Body).Decode(&defaultCheck); err != nil {
		t.Fatalf("error decodificando JSON: %v", err)
	}

	if defaultCheck.IntervalS != 30 {
		t.Fatalf("esperaba que el intervalo por defecto fuera 30, obtuve: %d", defaultCheck.IntervalS)
	}
}

func TestMetricsIncrement(t *testing.T) {
	app := newApp()

	// 1. Primera petición a un endpoint instrumentado (/api/checks)
	req := httptest.NewRequest(http.MethodGet, "/api/checks", nil)
	rec := httptest.NewRecorder()
	app.routes().ServeHTTP(rec, req)

	// 2. Consultamos métricas
	metReq := httptest.NewRequest(http.MethodGet, "/metrics", nil)
	metRec := httptest.NewRecorder()
	app.routes().ServeHTTP(metRec, metReq)

	// Verificamos que el contador de /api/checks (status 200) sea 1
	if !strings.Contains(metRec.Body.String(), `path="/api/checks",status="200"} 1`) {
		t.Fatalf("esperaba que el contador de /api/checks fuera 1, obtuve: %s", metRec.Body.String())
	}

	// 3. Segunda petición a /api/checks
	req2 := httptest.NewRequest(http.MethodGet, "/api/checks", nil)
	rec2 := httptest.NewRecorder()
	app.routes().ServeHTTP(rec2, req2)

	// 4. Consultamos métricas de nuevo
	metRec2 := httptest.NewRecorder()
	app.routes().ServeHTTP(metRec2, metReq)

	// Verificamos que el contador ahora sea 2
	if !strings.Contains(metRec2.Body.String(), `path="/api/checks",status="200"} 2`) {
		t.Fatalf("esperaba que el contador de /api/checks fuera 2, obtuve: %s", metRec2.Body.String())
	}
}
